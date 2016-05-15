# Kiwix for iOS  
Kiwix for iOS is an offline reader for wikipedia. Our mission is to give people equal and easy access to free knowledge of the world. Download it on [iTunes Store](https://itunes.apple.com/us/app/kiwix/id997079563).

## Compile Guide  
What you need:

- A Mac  
- Xcode 7.0 or up  

### Prepare  
1. Make sure Xcode is at least launched once and commnad line tool is installed
2. Install Macports 
3. sudo port install autoconf automake libtool
	
<!--HomeBrew:
*  brew install autoconf automake libtool gettext
*  brew link --force gettext-->

### Compile xz-5.2.2  
1. Download xz-5.2.2
2. ./autogen.sh
3. ./build-xz.sh

### Compile libzim  
1. Clone openzim [Git](git clone https://gerrit.wikimedia.org/r/p/openzim.git)
2. cd libzim
3. modify stat64 (to be elaborated)

To be continued...