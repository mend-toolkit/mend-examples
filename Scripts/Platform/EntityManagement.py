import argparse
import requests
import os
import re
import json
from dotenv import load_dotenv
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

# === Load environment variables ===
load_dotenv()

ORG_UUID = os.getenv("ORG_UUID")
JWT_TOKEN = os.getenv("JWT_TOKEN")

HEADERS = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": f"Bearer {JWT_TOKEN}"
}

COMMAND_HELP = """
Available commands:

1. search-project-by-tag --tag key:value [--filter regex]
   - Search projects matching tag key:value with optional name filter. Supports regex.

2. label-projects-by-tag --tag key:value --label LABEL_NAME --target project|product
   - Apply a label to projects or products that match the tag. Supports regex.

3. bulk-label --tag-label-map '{"key:value": "label"}'
   - Assign a single label to projects based on tag pattern. Supports regex for key and value.

4. delete-label --label LABEL_NAME --target project|product
   - Remove the specified label from all matching projects or products.

5. delete-tag --tag key:value --target project|product [--entity-id ENTITY_UUID | --all]
   - Delete a specific key:value tag from one entity (--entity-id) or bulk delete that tag:value pair across all entities of the target type (--all).

6. delete-by-tag --tag key:value --target project|product [--dry-run]
   - Bulk delete entire entities with the given tag. Supports regex and dry-run.

7. delete-by-label --label LABEL_NAME --target project|product [--dry-run]
   - Bulk delete entities with the given label. Supports regex and dry-run.

8. delete-unlabeled --dry-run
   - Delete products (applications) that have no labels.

9. list-all
   - List all entities (products and projects) with their tags and labels.

All deletion commands prompt for confirmation before execution unless dry-run is used.
"""


def get_all_entities():
    """Fetch all entities (projects and products) with paging."""
    all_entities = []
    start_index = 0
    page_size = 500
    while True:
        params = {"startIndex": start_index, "pageSize": page_size}
        url = f"https://api-saas.whitesourcesoftware.com/api/v2.0/orgs/{ORG_UUID}/entities"
        resp = requests.get(url, headers=HEADERS, params=params)
        if resp.status_code != 200:
            raise Exception(f"❌ Failed to fetch entities: {resp.status_code}\n{resp.text}")
        batch = resp.json().get("retVal", [])
        if not batch:
            break
        all_entities.extend(batch)
        if len(batch) < page_size:
            break
        start_index += page_size
    return all_entities


def deduplicate_entities(entities):
    """Deduplicate list of entities by UUID."""
    seen = set()
    unique = []
    for entity in entities:
        uid = entity.get("uuid")
        if uid and uid not in seen:
            seen.add(uid)
            unique.append(entity)
    return unique


def add_label_to_entity(entity_type, entity_uuid, label_name):
    """Add a label to a single project or product."""
    if entity_type == "project":
        url = f"https://api-saas.whitesourcesoftware.com/api/v3.0/orgs/{ORG_UUID}/projects/{entity_uuid}/labels"
    else:
        url = f"https://api-saas.whitesourcesoftware.com/api/v3.0/orgs/{ORG_UUID}/products/{entity_uuid}/labels"
    payload = json.dumps({"value": label_name})
    resp = requests.put(url, headers=HEADERS, data=payload)
    return resp.status_code == 200


def delete_label_from_entities(label_name, target):
    """Bulk remove a label from all matching entities."""
    entities = get_all_entities()
    affected = [item[target] for item in entities if target in item]
    affected = [e for e in affected if e and any(l.get("displayName") == label_name for l in e.get("labels", []))]
    print(f"🔍 Found {len(affected)} {target}(s) with label '{label_name}' :")
    for e in affected:
        print(f"- {e['name']} (UUID: {e['uuid']})")
    confirm = input("❗ Confirm removal? Type 'yes': ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled.")
        return
    for e in affected:
        url = f"https://api-saas.whitesourcesoftware.com/api/v3.0/orgs/{ORG_UUID}/{target}s/{e['uuid']}/labels/{label_name}"
        resp = requests.delete(url, headers=HEADERS)
        if resp.status_code == 200:
            print(f"✅ Removed label '{label_name}' from {e['name']}")
        else:
            print(f"❌ Failed for {e['name']}: {resp.status_code}")


def delete_tag_by_key_value(tag_pattern, target, entity_id=None):
    """Delete a specific key:value tag (exact key, substring value) with paging."""
    if ':' not in tag_pattern:
        print("❌ --tag must be key:value")
        return
    key_pat, val_pat = tag_pattern.split(':', 1)
    key_re = re.compile(key_pat)
    val_re = re.compile(val_pat)
    entities = get_all_entities()
    if entity_id:
        ent = next((item[target] for item in entities if target in item and item[target].get('uuid') == entity_id), None)
        candidates = [ent] if ent else []
    else:
        candidates = []
        for item in entities:
            ent = item.get(target)
            if not ent: continue
            for t in ent.get('tags', []):
                if isinstance(t, dict) and key_re.fullmatch(t.get('key','').strip()) and val_re.search(t.get('value','').strip()):
                    candidates.append(ent)
                    break
        candidates = deduplicate_entities(candidates)
    print(f"🔍 Found {len(candidates)} {target}(s) with tag '{tag_pattern}':")
    for e in candidates:
        print(f"- {e['name']} (UUID: {e['uuid']})")
    confirm = input("❗ Remove key:value tag? Type 'yes': ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled.")
        return
    for e in candidates:
        url = f"https://api-saas.whitesourcesoftware.com/api/v2.0/orgs/{ORG_UUID}/{target}s/{e['uuid']}/tags/{key_pat}:{val_pat}"
        resp = requests.delete(url, headers=HEADERS)
        if resp.status_code == 200:
            print(f"✅ Removed tag for {e['name']}")
        else:
            print(f"❌ Failed for {e['name']}: {resp.status_code}")


def bulk_label_projects(tag_label_map):
    """Apply a label based on tag:value patterns to all matching projects."""
    entities = get_all_entities()
    updated = []
    if len(tag_label_map) != 1:
        print("❌ Error: Only one tag-label mapping is allowed.")
        return
    keyval, label = next(iter(tag_label_map.items()))
    if ':' not in keyval:
        print("❌ Error: Tag-label key must be in key:value format.")
        return
    key_pat, val_pat = keyval.split(':', 1)
    key_re = re.compile(key_pat)
    val_re = re.compile(val_pat)
    for item in entities:
        proj = item.get('project')
        if not proj: continue
        for t in proj.get('tags', []):
            if isinstance(t, dict) and key_re.fullmatch(t.get('key','').strip()) and val_re.search(t.get('value','').strip()):
                if add_label_to_entity('project', proj['uuid'], label):
                    updated.append(proj['name'])
                break
    print(json.dumps({'updated_projects': updated}, indent=2))


def delete_unlabeled_products(dry_run=False):
    """Delete all products without labels or dry-run."""
    entities = get_all_entities()
    unlabeled = [item['product'] for item in entities if 'product' in item and not item['product'].get('labels')]
    unlabeled = deduplicate_entities(unlabeled)
    print(f"🔍 Found {len(unlabeled)} unlabeled products:")
    for p in unlabeled:
        print(f"- {p['name']} (UUID: {p['uuid']})")
    if dry_run or not unlabeled:
        print("💡 Dry run or no products to delete.")
        return
    confirm = input("❗ Delete these products? Type 'yes': ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled.")
        return
    for p in unlabeled:
        url = f"https://api-saas.whitesourcesoftware.com/api/v2.0/products/{p['uuid']}"
        resp = requests.delete(url, headers=HEADERS)
        if resp.status_code == 200:
            print(f"✅ Deleted product: {p['name']}")
        else:
            print(f"❌ Failed for {p['name']}: {resp.status_code}")


def search_project_by_tag(tag_pattern, name_filter=None):
    """List projects matching a given tag:value pair with optional name filter."""
    key_pat, val_pat = tag_pattern.split(':', 1)
    key_re = re.compile(key_pat)
    val_re = re.compile(val_pat)
    results = []
    entities = get_all_entities()
    for item in entities:
        proj = item.get('project')
        if not proj: continue
        if name_filter and not re.search(name_filter, proj.get('name','')): continue
        for t in proj.get('tags', []):
            if isinstance(t, dict) and key_re.fullmatch(t.get('key','').strip()) and val_re.search(t.get('value','').strip()):
                results.append({
                    'name': proj['name'],
                    'uuid': proj['uuid'],
                    'matched_tag': t,
                    'labels': [lbl.get('displayName') for lbl in proj.get('labels', [])]
                })
                break
    print(json.dumps({'matched_projects': results}, indent=2))


def delete_entities_by_tag(tag_pattern, target, dry_run=False):
    """Bulk delete entities matching a tag:value pattern."""
    key_pat, val_pat = tag_pattern.split(':', 1)
    key_re = re.compile(key_pat)
    val_re = re.compile(val_pat)
    entities = get_all_entities()
    matched = []
    for item in entities:
        ent = item.get(target)
        if not ent: continue
        for t in ent.get('tags', []):
            if isinstance(t, dict) and key_re.fullmatch(t.get('key','').strip()) and val_re.search(t.get('value','').strip()):
                matched.append(ent)
                break
    matched = deduplicate_entities(matched)
    print(f"🔍 Found {len(matched)} {target}(s) with tag '{tag_pattern}':")
    for e in matched:
        print(f"- {e['name']} (UUID: {e['uuid']})")
    if dry_run or not matched:
        print("💡 Dry run or no entities to delete.")
        return
    confirm = input("❗ Delete these entities? Type 'yes': ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled.")
        return
    for e in matched:
        url = (f"https://api-saas.whitesourcesoftware.com/api/v2.0/orgs/{ORG_UUID}/projects/{e['uuid']}" if target=='project' else f"https://api-saas.whitesourcesoftware.com/api/v2.0/products/{e['uuid']}")
        resp = requests.delete(url, headers=HEADERS)
        if resp.status_code == 200:
            print(f"✅ Deleted {target}: {e['name']}")
        else:
            print(f"❌ Failed for {e['name']}: {resp.status_code}")


def delete_entities_by_label(label_name, target, dry_run=False):
    """Bulk delete entities matching a label."""
    entities = get_all_entities()
    matched = [item.get(target) for item in entities if target in item and any(lbl.get('displayName')==label_name for lbl in item[target].get('labels',[]))]
    matched = deduplicate_entities(matched)
    print(f"🔍 Found {len(matched)} {target}(s) with label '{label_name}':")
    for e in matched:
        print(f"- {e['name']} (UUID: {e['uuid']})")
    if dry_run or not matched:
        print("💡 Dry run or no entities to delete.")
        return
    confirm = input("❗ Delete these entities? Type 'yes': ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled.")
        return
    for e in matched:
        url = (f"https://api-saas.whitesourcesoftware.com/api/v2.0/orgs/{ORG_UUID}/projects/{e['uuid']}" if target=='project' else f"https://api-saas.whitesourcesoftware.com/api/v2.0/products/{e['uuid']}")
        resp = requests.delete(url, headers=HEADERS)
        if resp.status_code == 200:
            print(f"✅ Deleted {target}: {e['name']}")
        else:
            print(f"❌ Failed for {e['name']}: {resp.status_code}")


def list_all_entities():
    """List all entities with their tags and labels."""
    entities = []
    for item in get_all_entities():
        for kind in ('project','product'):
            ent = item.get(kind)
            if ent:
                entities.append({
                    'type': kind,
                    'name': ent.get('name'),
                    'uuid': ent.get('uuid'),
                    'tags': ent.get('tags',[]),
                    'labels': [lbl.get('displayName') for lbl in ent.get('labels',[])]
                })
    entities = deduplicate_entities(entities)
    print(json.dumps({'entities': entities}, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Mend Entity Management CLI")
    parser.add_argument('action', choices=[
        'search-project-by-tag','label-projects-by-tag','bulk-label',
        'delete-label','delete-tag','delete-by-tag','delete-by-label',
        'delete-unlabeled','list-all'
    ], help='Action to perform')
    parser.add_argument('--tag', help="Tag to filter or manipulate (key:value; regex supported)", required=False)
    parser.add_argument('--label', help="Label to add/delete when matched", required=False)
    parser.add_argument('--target', choices=['project','product'], help="Target entity type", required=False)
    parser.add_argument('--tag-label-map', help="JSON mapping of tag:value to label for bulk-label (regex supported)", required=False)
    parser.add_argument('--entity-id', help="UUID of single entity (for delete-tag)", required=False)
    parser.add_argument('--all', action='store_true', help="Bulk remove key:value tags from all entities of the target type")
    parser.add_argument('--dry-run', action='store_true', help="Preview only, no deletion")
    parser.add_argument('--filter', help="Regex filter for name (search-project-by-tag)", required=False)

    args = parser.parse_args()
    if args.action == 'list-all':
        list_all_entities()
    elif args.action == 'delete-unlabeled':
        delete_unlabeled_products(dry_run=args.dry_run)
    elif args.action == 'bulk-label':
        if not args.tag_label_map:
            print("❌ --tag-label-map is required for bulk-label")
        else:
            try:
                mapping = json.loads(args.tag_label_map)
                bulk_label_projects(mapping)
            except json.JSONDecodeError:
                print("❌ --tag-label-map must be valid JSON")
    elif args.action == 'search-project-by-tag':
        if not args.tag or ':' not in args.tag:
            print("❌ --tag must be in key:value format")
        else:
            search_project_by_tag(args.tag, args.filter)
    elif args.action == 'delete-by-tag':
        if not args.tag or not args.target:
            print("❌ --tag and --target are required for delete-by-tag")
        else:
            delete_entities_by_tag(args.tag, args.target, dry_run=args.dry_run)
    elif args.action == 'delete-tag':
        if not args.tag or not args.target:
            print("❌ --tag and --target are required for delete-tag")
        elif args.entity_id:
            delete_tag_by_key_value(args.tag, args.target, entity_id=args.entity_id)
        elif args.all:
            delete_tag_by_key_value(args.tag, args.target)
        else:
            print("❌ Must specify either --entity-id or --all for delete-tag")
    elif args.action == 'delete-label':
        if not args.label or not args.target:
            print("❌ --label and --target are required for delete-label")
        else:
            delete_label_from_entities(args.label, args.target)
    elif args.action == 'delete-by-label':
        if not args.label or not args.target:
            print("❌ --label and --target are required for delete-by-label")
        else:
            delete_entities_by_label(args.label, args.target, dry_run=args.dry_run)
    else:
        print(COMMAND_HELP)

    print(COMMAND_HELP)

if __name__ == '__main__':
    main()
