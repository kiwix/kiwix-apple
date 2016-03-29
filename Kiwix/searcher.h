/*
 * Copyright 2011 Emmanuel Engelhart <kelson@kiwix.org>
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

#ifndef KIWIX_SEARCHER_H
#define KIWIX_SEARCHER_H

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <algorithm>
#include <vector>
#include <locale>
#include <cctype>
#include <vector>
#include <resourceTools.h>
#include <pathTools.h>
#include <stringTools.h>
#include "unicode/putil.h"

#ifdef __APPLE__
    #ifndef TARGET_OS_IPHONE
        #include <ctpp2/CDT.hpp>
        #include <ctpp2/CTPP2FileLogger.hpp>
        #include <ctpp2/CTPP2SimpleVM.hpp>

        #include "kiwix/ctpp2/CTPP2VMStringLoader.hpp"
    #endif
#endif

using namespace std;

#ifdef __APPLE__
    #ifndef TARGET_OS_IPHONE
        using namespace CTPP;
    #endif
#endif

struct Result
{
  string url;
  string title;
  int score;
  string snippet;
  int wordCount;
  int size;
};

namespace kiwix {

  class Searcher {

  public:
    Searcher();

    void search(std::string &search, unsigned int resultStart,
		unsigned int resultEnd, const bool verbose=false);
    bool getNextResult(string &url, string &title, unsigned int &score);
    unsigned int getEstimatedResultCount();
    bool setProtocolPrefix(const std::string prefix);
    bool setSearchProtocolPrefix(const std::string prefix);
    string getHtml();
    void reset();
    void setContentHumanReadableId(const string &contentHumanReadableId);
    ~Searcher();

  protected:
    std::string beautifyInteger(const unsigned int number);
    virtual void closeIndex() = 0;
    virtual void searchInIndex(string &search, const unsigned int resultStart,
			       const unsigned int resultEnd, const bool verbose=false) = 0;

    std::vector<Result> results;
    std::vector<Result>::iterator resultOffset;
    std::string searchPattern;
    std::string protocolPrefix;
    std::string searchProtocolPrefix;
    std::string template_ct2;
    unsigned int resultCountPerPage;
    unsigned int estimatedResultCount;
    unsigned int resultStart;
    unsigned int resultEnd;
    std::string contentHumanReadableId;
  };

}

#endif
