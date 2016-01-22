# Kiwix for iOS  
Kiwix for iOS is a offline reader for the web. It's mission is to give people equal and easy access to free knowledge of the world. Download it on [iTunes Store](https://itunes.apple.com/us/app/kiwix/id997079563).

## Compile Guide  
What you need:

- A Mac  
- Xcode 7.0  

### Prepare  
1. Install Macports
2. sudo port install autoconf automake libtool

### Compile xz-5.2.2  
1. Download xz-5.2.2
2. ./autogen.sh
3. ./build-xz.sh

### Compile libzim  
1. Clone openzim [Git](git clone https://gerrit.wikimedia.org/r/p/openzim.git)
2. cd libzim
3. modify stat64 (to be elaborated)

To be continued...