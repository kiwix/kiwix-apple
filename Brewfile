brew "pre-commit"
brew "xcodegen"
brew "curl"

at_exit do
    system "pre-commit install"
    system "curl -L -o - https://download.kiwix.org/release/libkiwix/libkiwix_xcframework-14.0.0-1.tar.gz | tar -x --strip-components 2"
    # Copy Clang module map to xcframework for Swift C++ Interoperability 
    system "cp Support/CoreKiwix.modulemap CoreKiwix.xcframework/ios-arm64/Headers/module.modulemap"
    system "cp Support/CoreKiwix.modulemap CoreKiwix.xcframework/ios-arm64_x86_64-simulator/Headers/module.modulemap"
    system "cp Support/CoreKiwix.modulemap CoreKiwix.xcframework/macos-arm64_x86_64/Headers/module.modulemap"
    system "xcodegen"
end
