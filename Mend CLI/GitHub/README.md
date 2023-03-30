Yaml files should be customized with proper steps for specific builds


# Android
```
    - name: Setup Android SDK
      uses: android-actions/setup-android@v2
    - name: Grant execute permission for gradlew
      run: |
        chmod +x gradlew
        echo "ANDROID_HOME:" $ANDROID_HOME
    - name: Build with Gradle
      run: ./gradlew build
```

# DOTNET
```
    - name: Setup .NET
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: 5.0.x
    - name: Restore dependencies
      run: dotnet restore
```
Env variables are typically set beneath the build job name for dotnet
```
jobs:
  mendscan:
    env:
      BUILD_CONFIG: 'Release'
      SOLUTION: 'MySolution.sln'
```

# GO
```
    - name: Set up Go
      uses: actions/setup-go@v2
      with:
        go-version: 1.17
    - name: Go Build
      run: go build -v ./...
```

# LUA
```
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
```
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
```
    - name: Setup Nodejs
      uses: actions/setup-node@v3
      with:
        node-version: 16
    - name: Install node modules
      run: npm install
```

# NUGET
```
    - name: Setup NuGet
      uses: NuGet/setup-nuget@v1.0.5
    - name: Restore dependencies
      run: nuget restore $SOLUTION
```
Env variables are typically set beneath the build job name for nuget
```
jobs:
  mendscan:
    env:
      BUILD_CONFIG: 'Release'
      SOLUTION: 'MySolution.sln'
```

# Swift
Runs on ```runs-on: macos-latest```
```
    - name: Build
      run: swift build -v
```
