/*
 * Copyright 2011-2014 Emmanuel Engelhart <kelson@kiwix.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU  General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */

#include "pathTools.h"

#ifdef __APPLE__
#include <mach-o/dyld.h>
#include <limits.h>
#elif _WIN32
#include <windows.h>
#include "Shlwapi.h"
#endif

#ifdef _WIN32
#else
#include <unistd.h>
#endif

#ifdef _WIN32
#define SEPARATOR "\\"
#else
#define SEPARATOR "/"
#endif

#ifndef PATH_MAX
#define PATH_MAX 1024
#endif

bool isRelativePath(const string &path) {
#ifdef _WIN32
  return path.empty() || path.substr(1, 2) == ":\\" ? false : true;
#else
  return path.empty() || path.substr(0, 1) == "/" ? false : true;
#endif
}

string computeRelativePath(const string path, const string absolutePath) {
  std::vector<std::string> pathParts = kiwix::split(path, SEPARATOR);
  std::vector<std::string> absolutePathParts = kiwix::split(absolutePath, SEPARATOR);

  unsigned int commonCount = 0;
  while (commonCount < pathParts.size() && 
	 commonCount < absolutePathParts.size() && 
	 pathParts[commonCount] == absolutePathParts[commonCount]) {
    if (!pathParts[commonCount].empty()) {
      commonCount++;
    }
  }
  
  string relativePath;
#ifdef _WIN32
  /* On Windows you have a token more because the root is represented
     by a letter */
  if (commonCount == 0) {
    relativePath = "../";
  }
#endif

  for (unsigned int i = commonCount ; i < pathParts.size() ; i++) {
    relativePath += "../";
  }
  for (unsigned int i = commonCount ; i < absolutePathParts.size() ; i++) {
    relativePath += absolutePathParts[i];
    relativePath += i + 1 < absolutePathParts.size() ? "/" : "";
  }

  return relativePath;
}

/* Warning: the relative path must be with slashes */
string computeAbsolutePath(const string path, const string relativePath) {
  string absolutePath;

  if (path.empty()) {
    char *path=NULL;
    size_t size = 0;

#ifdef _WIN32
    path = _getcwd(path, size);
#else
    path = getcwd(path, size);
#endif

    absolutePath = string(path) + SEPARATOR;
  } else {
    absolutePath = path.substr(path.length() - 1, 1) == SEPARATOR ? path : path + SEPARATOR;
  }

#if _WIN32
  char *cRelativePath = _strdup(relativePath.c_str());
#else
  char *cRelativePath = strdup(relativePath.c_str());
#endif
  char *token = strtok(cRelativePath, "/");

  while (token != NULL) {
    if (string(token) == "..") {
      absolutePath = removeLastPathElement(absolutePath, true, false);
      token = strtok(NULL, "/");
    } else if (strcmp(token, ".") && strcmp(token, "")) {
      absolutePath += string(token);
      token = strtok(NULL, "/");
      if (token != NULL)
	absolutePath += SEPARATOR;
    } else {
      token = strtok(NULL, "/");
    }
  }

  return absolutePath;
}

string removeLastPathElement(const string path, const bool removePreSeparator, const bool removePostSeparator) {
  string newPath = path;
  size_t offset = newPath.find_last_of(SEPARATOR);
  if (removePreSeparator && 
#ifndef _WIN32
      offset != newPath.find_first_of(SEPARATOR) && 
#endif
      offset == newPath.length()-1) {
    newPath = newPath.substr(0, offset);
    offset = newPath.find_last_of(SEPARATOR);
  }
  newPath = removePostSeparator ? newPath.substr(0, offset) : newPath.substr(0, offset+1);
  return newPath;
}

string appendToDirectory(const string &directoryPath, const string &filename) {
  string newPath = directoryPath + SEPARATOR + filename;
  return newPath;
}

string getLastPathElement(const string &path) {
  return path.substr(path.find_last_of(SEPARATOR) + 1);
}

unsigned int getFileSize(const string &path) {
#ifdef _WIN32
  struct _stat filestatus;
  _stat(path.c_str(), &filestatus);
#else
  struct stat filestatus;
  stat(path.c_str(), &filestatus);
#endif

  return filestatus.st_size / 1024;
}

string getFileSizeAsString(const string &path) {
  ostringstream convert; convert << getFileSize(path);
  return convert.str();
}

bool fileExists(const string &path) {
#ifdef _WIN32
  return PathFileExists(path.c_str());
#else
  bool flag = false;
  fstream fin;
  fin.open(path.c_str(), ios::in);
  if (fin.is_open()) {
    flag = true;
  }
  fin.close();
  return flag;
#endif
}

bool makeDirectory(const string &path) {
#ifdef _WIN32
  int status = _mkdir(path.c_str());
#else
  int status = mkdir(path.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
#endif
  return status == 0;
}

/* Try to create a link and if does not work then make a copy */
bool copyFile(const string &sourcePath, const string &destPath) {
  try {
#ifndef _WIN32
    if (link(sourcePath.c_str(), destPath.c_str()) != 0) {
#endif
	std::ifstream infile(sourcePath.c_str(), std::ios_base::binary);
	std::ofstream outfile(destPath.c_str(), std::ios_base::binary);
	outfile << infile.rdbuf();
#ifndef _WIN32
    }
#endif
  } catch (exception &e) {
    cerr << e.what() << endl;
    return false;
  }

  return true;
}

string getExecutablePath() {
  char binRootPath[PATH_MAX];
  
#ifdef _WIN32
  GetModuleFileName( NULL, binRootPath, PATH_MAX);
  return std::string(binRootPath);
#elif __APPLE__
  uint32_t max = (uint32_t)PATH_MAX;
  _NSGetExecutablePath(binRootPath, &max);
  return std::string(binRootPath);
#else
  ssize_t size =  readlink("/proc/self/exe", binRootPath, PATH_MAX);
  if (size != -1) {
    return std::string(binRootPath, size);
  }
#endif

  return "";
}

bool writeTextFile(const string &path, const string &content) {
  std::ofstream file;
  file.open(path.c_str());
  file << content;
  file.close();
  return true;
}
