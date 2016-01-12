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

#ifndef KIWIX_READER_H
#define KIWIX_READER_H

#include <zim/zim.h>
#include <zim/file.h>
#include <zim/article.h>
#include <zim/fileiterator.h>
#include <stdio.h>
#include <string>
#include <exception>
#include <sstream>
#include <map>
#include "time.h"
#include <pathTools.h>
#include <stringTools.h>

using namespace std;

namespace kiwix {

  class Reader {

  public:
    Reader(const string zimFilePath);
    ~Reader();

    void reset();
    unsigned int getArticleCount();
    unsigned int getMediaCount();
    unsigned int getGlobalCount();
    string getId();
    string getRandomPageUrl();
    string getFirstPageUrl();
    string getMainPageUrl();
    bool getMetatag(const string &url, string &content);
    string getTitle();
    string getDescription();
    string getLanguage();
    string getDate();
    string getCreator();
    string getPublisher();
    string getOrigId();
    bool getFavicon(string &content, string &mimeType);
    bool getPageUrlFromTitle(const string &title, string &url);
    bool getMimeTypeByUrl(const string &url, string &mimeType);
    bool getContentByUrl(const string &url, string &content, unsigned int &contentLength, string &contentType);
    bool getContentByEncodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType, string &baseUrl);
    bool getContentByEncodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType);
    bool getContentByDecodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType, string &baseUrl);
    bool getContentByDecodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType);
    bool searchSuggestions(const string &prefix, unsigned int suggestionsCount, const bool reset = true);
    bool searchSuggestionsSmart(const string &prefix, unsigned int suggestionsCount);
    std::vector<std::string> getTitleVariants(const std::string &title);
    bool getNextSuggestion(string &title);
    bool getNextSuggestion(string &title, string &url);
    bool canCheckIntegrity();
    bool isCorrupted();
    bool parseUrl(const string &url, char *ns, string &title);
    unsigned int getFileSize();
    zim::File* getZimFileHandler();

  protected:
    zim::File* zimFileHandler;
    zim::size_type firstArticleOffset;
    zim::size_type lastArticleOffset;
    zim::size_type currentArticleOffset;
    zim::size_type nsACount;
    zim::size_type nsICount;

    std::vector< std::vector<std::string> > suggestions;
    std::vector< std::vector<std::string> >::iterator suggestionsOffset;

  private:
    std::map<std::string, unsigned int> parseCounterMetadata();
    bool getArticleObjectByDecodedUrl(const string &url, zim::Article &article);
  };

}

#endif
