#include <resourceTools.h>
#include <iostream>

std::string getResourceAsString(const std::string &name) {
  std::map<std::string, std::pair<const unsigned char*, unsigned int> >::iterator it = resourceMap.find(name);
  if (it != resourceMap.end()) {
    return std::string((const char*)resourceMap[name].first, resourceMap[name].second);
  }
  return "";
}
