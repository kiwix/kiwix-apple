/*
 * Copyright 2011-2012 Emmanuel Engelhart <kelson@kiwix.org>
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

#ifndef KIWIX_STRINGTOOLS_H
#define KIWIX_STRINGTOOLS_H

#include <unicode/translit.h>
#include <unicode/normlzr.h>
#include <unicode/unistr.h>
#include <unicode/rep.h>
#include <unicode/translit.h>
#include <unicode/uniset.h>
#include <unicode/ustring.h>
#include <unicode/ucnv.h>

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>

#include <pathTools.h>

namespace kiwix {

#ifndef __ANDROID__

  std::string removeAccents(const std::string &text);
  std::string beautifyInteger(const unsigned int number);
  std::string beautifyFileSize(const unsigned int number);
  std::string urlEncode(const std::string &c);
  void printStringInHexadecimal(const char *s);
  void printStringInHexadecimal(UnicodeString s);
  void stringReplacement(std::string& str, const std::string& oldStr, const std::string& newStr);
  std::string encodeDiples(const std::string& str);

#endif

  void loadICUExternalTables();
  std::string urlDecode(const std::string &c);

  std::vector<std::string> split(const std::string&, const std::string&);
  std::vector<std::string> split(const char*, const char*);
  std::vector<std::string> split(const std::string&, const char*);
  std::vector<std::string> split(const char*, const std::string&);

  std::string ucAll(const std::string &word);
  std::string lcAll(const std::string &word);
  std::string ucFirst(const std::string &word);
  std::string lcFirst(const std::string &word);
  std::string toTitle(const std::string &word);

  std::string normalize(const std::string &word);
}

#endif
