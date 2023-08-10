# Bls-Signature

Wrapper on BLS-Signature library to provide use .cpp implementation and use .c blst.a

https://github.com/Chia-Network/bls-signatures
clone by commit hash 900af6a06eed0349174e0d845a56556a619aec52

## Install

### 1. you need to compile blst.a library and place it in a category bls-signature in lib for any sdk

> ``sudo bash build_blst.sh``

### 2. Build fraemwork platform=iOS

> ``
    xcodebuild archive
    -scheme Bls-Signature 
    -destination "generic/platform=iOS" 
    -archivePath "archives/Bls-Signature-iOS"
    SKIP_INSTALL=NO
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
``

### 3. Build fraemwork platform=iOS Simulator

> ``
    xcodebuild archive
    -scheme Bls-Signature 
    -destination "generic/platform=iOS Simulator"
    -archivePath "archives/Bls-Signature-Simulator"
    SKIP_INSTALL=NO
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES
``

### 4. Assembly fraemworks for Cross Compile xcfraemwork

> ``xcodebuild -create-xcframework -framework archives/Bls-Signature-iOS.xcarchive/Products/Library/Frameworks/Bls_Signature.framework -framework archives/Bls-Signature-Simulator.xcarchive/Products/Library/Frameworks/Bls_Signature.framework -output Bls_Signature.xcframework``
