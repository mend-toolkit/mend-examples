Yaml files should be customized with proper steps for specific builds.  Below are a few examples for common GitHub Action build types.


# Android
```yml
    - name: Setup Android SDK
      uses: android-actions/setup-android@v2
    - name: Grant execute permission for gradlew
      run: |
        chmod +x gradlew
        echo "ANDROID_HOME:" $ANDROID_HOME
    - name: Build with Gradle
      run: ./gradlew build
```


# DOTNET/NUGET
```yml
    - name: Setup .NET
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: 5.0.x
    - name: Restore dependencies
      run: dotnet restore
    - name: Setup NuGet
      uses: NuGet/setup-nuget@v1.0.5
    - name: Restore dependencies
      run: nuget restore $SOLUTION
```
Env variables are typically set beneath the build job name for dotnet
```yml
jobs:
  mendscan:
    env:
      BUILD_CONFIG: 'Release'
      SOLUTION: 'MySolution.sln'
```

# GO
```yml
    - name: Set up Go
      uses: actions/setup-go@v2
      with:
        go-version: 1.17
    - name: Go Build
      run: go build -v ./...
```

# LUA
```yml
    - name: Setup Lua
      uses: leafo/gh-actions-lua@v8
      with:
        luaVersion: 5.4.3
    - name: Setup Luarocks
      uses: leafo/gh-actions-luarocks@v4
    - name: LuaRocks Build
      run: luarocks build --tree=./
```

# Maven
```yml
    - name: Set up JDK
      uses: actions/setup-java@v2
      with:
        java-version: '11'
        distribution: 'adopt'
    - name: Build with Maven
      run: mvn clean install -DskipTests=true
```

# NPM
Only required if a package-lock.json does not exist
```yml
    - name: Setup Nodejs
      uses: actions/setup-node@v3
      with:
        node-version: 16
    - name: Install node modules
      run: npm install --only=prod
```
# Python
```yml
    - name: Set up Python 
      uses: actions/setup-python@v2
      with:
        python-version: 3.7
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install virtualenv --user
        pip install -r requirements.txt
```
# Swift
```yml
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v2
    - name: Build
      run: swift build -v
```

## Publishing Mend Unified Agent Logs From a Pipeline

Publish the `whitesource` folder with logs & reports by adding one the following commands, depending on your platform


```yaml
- name: 'Upload WhiteSource folder'
  uses: actions/upload-artifact@v2
  with:
    name: WhiteSource
    path: whitesource
    retention-days: 1
- name: 'Upload WhiteSource folder if failure'
  uses: actions/upload-artifact@v2
  if: failure()
  with:
    name: WhiteSource
    path: whitesource
    retention-days: 1
```

## Publishing Mend CLI Logs From a Pipeline

* Publish the `.mend/logs` folder with logs & reports by adding the following commands depending on each pipeline
  * SAST logs are currently located in ```.mend/storage/sast/logs```

```yaml
- name: 'Upload Mend CLI Logs if failure'
    uses: actions/upload-artifact@v2
    with:
        name: "Mend CLI Logs"
        path: ~/.mend/logs
        retention-days: 1
- name: 'Upload Mend CLI Logs if failure'
    uses: actions/upload-artifact@v2
    if: failure()
    with:
        name: "Mend CLI Logs"
        path: ~/.mend/logs
        retention-days: 1
```
