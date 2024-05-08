import os
import sys
import json
import pgpy
from pgpy import PGPKey
from pgpy.constants import CompressionAlgorithm
import warnings
import argparse
from argparse import Namespace

"""
******** Mend Script to encrypt credentials for repository integration hostRules********

Users should feel free to edit this file to make appropriate changes for desired behavior.

******** Description ********
This script takes information from either environment variables, or command line flags and
encrypts the information to be used in .whitesource, repo-config.json, or renovate.json files.

The execution process looks like:
1. Get information for encryption
2. Determine the key needed for encryption
3. Encrypt the Information using Python's PGPy package.

******** Usage ********
Make sure to install the appropriate dependencies before running this script and set all required environment variables. You can run the script with:
pip3 install pgpy argparse
python3 encrypt_credentials.py -o "<organization>" -r "<repository>" -v "<secret_value>"

For more information run the following command:
python3 encrypt_credentials.py -h

Pre-requisites:
apt-get install python3.10
pip install pgpy argparse
export ORGANIZATION="<your SCM Organization Name>"
export REPOSITORY="<your repository name>"
export SECRET_VALUE="<your credential>"
"""

PUBLIC_KEY = """-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBGE7rc8BCACofJTBvhmvXEU5hXV7FR/J1Wk9c8XheTp0QLOpBNMT6Vi07dkG
d0GGPIFxVFMt5GzMlpLHfAWgzIpZ2qkdzfLGNguwcSyTs7PsGBaVPebEDSaKXEhl
c2cyeP5UC8MoU0EyuiyOeYMyIx2+hRPTnwkF5p7QJp3hHFIfh4Q7vT9p2aW7/aGu
35Qn1JSDxBPdlw3jYRJ4WEKYWLWrI1Hd8lxCvG6Xlejr7RG8igk3BPq1lAqTHKAs
hhmu62Ya/Gv241y33geMtA8fVSOrBfl27DZanfvVk7NYaAJHwlHfalWjVDZQ7RLw
z2mHpKrGjyMfBFSUBWE7nkNfwDmwsF8nibVhABEBAAG0N1doaXRlU291cmNlIChv
cHMtMTk5MikgPGRldm9wc0B3aGl0ZXNvdXJjZXNvZnR3YXJlLmNvbT6JAU4EEwEK
ADgWIQQ4e2sDkaxy/aWIaNSWN0enegTMagUCYTutzwIbAwULCQgHAgYVCgkICwIE
FgIDAQIeAQIXgAAKCRCWN0enegTMakZ/B/9kAIQSWSIsPZtrbOF/okLPwkfY16m9
qhJJO8xk9/QzbqM6Zf7avBEqJhf/Up1AWeEQclHQRZR5bnicBGK16MU4tg+Re4fd
y3HkFdzh/qUeLszEH0PXrkd4gvrO6txBJ504c683aaHH3DG9H6vooIYea/hek8Th
rEAIKvg4GSWCeFqe8Nd1C0sQMgRIzK4gwge8RV3e50/9ftZms3ncvRP//j/ZjguI
/xQ0ZxhUZbCsTJRYCIecBGCf2qR699VKagD4ZkEQ7cvQYayRvWvxFGvqgwv8br8s
NiEYHavrTIrUQduwS+KpN0uGJwo6gHKMjJbwUOAcSzWUxhKwboAlFTtwuQENBGE7
rc8BCACgibOBpFumSyMWu0hrNlQemz38YEQDVVRgNC1+sOVCnMWZ9VY7H2GFonva
YcP5bKvs82zfT764JfDXXWcoCtmUC64/BtxSN2uNSzWk/KaYVY7uCEcR+tV1L1fJ
UlwysvmIuGsxtBXBMPGmwUJnjujwuEDh2KOokEntLIH8w1xhk4sMbObj1enhp9ig
kQciZWlXDHrTvasvVH3VYcw2e2SbfN+psxWPmUutG2G/U84QBpTHqns/5ugt+QIU
ZaAtd2OzuVcdRNhdPpK4TuBpNK96Cni/uHyIa9g4MnpRAeLDtfbJeyhJca+GtBR1
9ERRiygLb5mcz3AKjAYQHNcH0doPABEBAAGJATYEGAEKACAWIQQ4e2sDkaxy/aWI
aNSWN0enegTMagUCYTutzwIbDAAKCRCWN0enegTMavIDB/9TMIdo98RpqVddzs2k
s4dNkY3lDPbN0b5AHWg04rNd/DtY1Ui5tktBU1efnJ+0V/qRSwINTbIusbY+OKYi
kgAFN0wwItcqZnGE/MG03SxJm7U1gOv82bGqga6xFyYQUJKZ87TTVtnj+o0d/zRK
ezVCC67jjFssZIAua6StmRcEXHJQiDc/wgP/I0Bt0RN4cBcFVj/Dm+8x59gGlTfh
Adn3msCvBmeoLW3XcqU+ZAaV4ZepcqAJrIoiZHPxfymj7UQZD/ybFnzazuhzVpY1
88F6pAAA0LbhA5Qd97M7uM6h2LcFoUVK8roEw425Vh25fqj7qz7PIpOBSM9Wbab1
Sd+q
=ZYBf
-----END PGP PUBLIC KEY BLOCK-----"""

RENOVATE_PUBLIC_KEY = """-----BEGIN PGP PUBLIC KEY BLOCK-----

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
ssLaqgsTBEsskys=
=nfs6
-----END PGP PUBLIC KEY BLOCK-----"""


# Parse Arguments provided to the utility. Order of precedence:
# 1. Command Line Flags
# 2. Environment Variables
def parse_args() -> Namespace:
    global PUBLIC_KEY
    global RENOVATE_PUBLIC_KEY

    parser = argparse.ArgumentParser(
        prog="encrypt_credentials.py",
        description="A script replacement for the Mend.io Host Rule encryption web pages",
    )

    parser.add_argument(
        "-o",
        "--organization",
        required=True,
        default=os.environ["ORGANIZATION"] if "ORGANIZATION" in os.environ else "",
        help="Organization Name (Environment Variable: ORGANIZATION)",
    )
    parser.add_argument(
        "-r",
        "--repository",
        required=False,
        default=os.environ["REPOSITORY"] if "REPOSITORY" in os.environ else "",
        help="Repository Name (Optional) (Environment Variable: REPOSITORY)",
    )
    parser.add_argument(
        "-v",
        "--secret-value",
        default=os.environ["SECRET_VALUE"] if "SECRET_VALUE" in os.environ else "",
        required=True,
        help="Secret Value (Environment Variable: SECRET_VALUE)",
    )

    # A mutually exclusive group means that its members can have either none, or one of the parameters, but not both.
    key_group = parser.add_mutually_exclusive_group()
    key_group.add_argument(
        "-k",
        "--public-key-file",
        default=os.environ["PUBLIC_KEY_FILE"]
        if "PUBLIC_KEY_FILE" in os.environ
        else "",
        required=False,
        help="Public Key File (Optional, Default: Cloud Repository Integration Public Key) (Environment Variable: PUBLIC_KEY_FILE)",
    )

    key_group.add_argument(
        "-rk",
        "--renovate-key",
        default=False,
        required=False,
        action=argparse.BooleanOptionalAction,
        help="Whether to use the Renovate Public key for renovate.json files",
    )

    arguments = parser.parse_args()

    # If there are flags set concerning the public key, parse them accordingly and then set information to the PUBLIC_KEY global.
    # If the public_key_file is set, then read the file and set the information in PUBLIC_KEY global variable.
    if arguments.public_key_file:
        try:
            with open(arguments.public_key_file, "r") as pubkey_file:
                PUBLIC_KEY = pubkey_file.read()
        except FileNotFoundError as e:
            print(f"File: {e.filename} not found. Please specify a valid key file")
            parser.print_help()
            sys.exit(-1)
    elif arguments.renovate_key:
        PUBLIC_KEY = RENOVATE_PUBLIC_KEY

    return arguments


def encrypt_value(value: str) -> str:
    global PUBLIC_KEY

    # Requires the value that needs to be encrypted. This value should be in JSON format like:
    # {"o":"<organization>","r":"<repository>","v":"secret_value"}
    # NOTE: the lack of whitespace is important

    message = pgpy.PGPMessage.new(value, compression=CompressionAlgorithm.Uncompressed)
    pubkey = PGPKey.from_blob(PUBLIC_KEY)

    encrypted_message = ""

    # The PGPKey.from_blob method is designed very weird, in the fact that it can return one of two types:
    # 1. PGPKey
    # 2. Tuple[PGPKey, Unknown]
    # Therefore, we have to check which type it returned.
    # See: https://www.reddit.com/r/learnpython/comments/16lst2m/is_this_really_a_pythonic_way_of_returning_objects/

    if isinstance(pubkey, PGPKey):
        encrypted_message = str(pubkey.encrypt(message))
    else:
        pubkey = pubkey[0]
        encrypted_message = str(pubkey.encrypt(message))

    # Format the message in a way that can be copied and pasted properly into the configuration file.
    encrypted_message = encrypted_message.split("\n")
    encrypted_message = encrypted_message[1:-1]
    encrypted_message = "".join(encrypted_message)
    encrypted_message = encrypted_message.split("=")[0]

    return encrypted_message


def main():
    arguments = parse_args()

    organization = arguments.organization
    repository = arguments.repository
    secret_key = arguments.secret_value

    # Create the Input Value. It needs to be in JSON format without whitespace.
    input = {"o": organization, "r": repository, "v": secret_key}
    inputString = json.dumps(input, separators=(",", ":"))

    encrypted_value = encrypt_value(inputString)

    print(f"Encrypted Secret Value:\n{encrypted_value}")


if __name__ == "__main__":
    # The PGPy library throws warnings when encrypting for unrelated encryption algorithms.
    # This setting filters out those warnings.
    warnings.filterwarnings(
        "ignore",
        ".*deprecated.*",
    )
    main()
