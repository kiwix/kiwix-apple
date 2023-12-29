brew "pre-commit"
brew "xcodegen"
brew "curl"

at_exit do
    system "pre-commit install"
    system "curl -L -o - https://download.kiwix.org/release/libkiwix/libkiwix_xcframework-13.0.0-1.tar.gz | tar -x --strip-components 2" 
    system "xcodegen"
end