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

#include "reader.h"

inline char hi(char v) {
    char hex[] = "0123456789abcdef";
    return hex[(v >> 4) & 0xf];
}

inline char lo(char v) {
    char hex[] = "0123456789abcdef";
    return hex[v & 0xf];
}

std::string hexUUID (std::string in) {
    std::ostringstream out;
    for (unsigned n = 0; n < 4; ++n)
      out << hi(in[n]) << lo(in[n]);
    out << '-';
    for (unsigned n = 4; n < 6; ++n)
      out << hi(in[n]) << lo(in[n]);
    out << '-';
    for (unsigned n = 6; n < 8; ++n)
      out << hi(in[n]) << lo(in[n]);
    out << '-';
    for (unsigned n = 8; n < 10; ++n)
      out << hi(in[n]) << lo(in[n]);
    out << '-';
    for (unsigned n = 10; n < 16; ++n)
      out << hi(in[n]) << lo(in[n]);
    std::string op=out.str();
    return op;
}

namespace kiwix {

  /* Constructor */
  Reader::Reader(const string zimFilePath)
    : zimFileHandler(NULL) {
    string tmpZimFilePath = zimFilePath;

    /* Remove potential trailing zimaa */
    size_t found = tmpZimFilePath.rfind("zimaa");
    if (found != string::npos &&
	tmpZimFilePath.size() > 5 &&
	found == tmpZimFilePath.size() - 5) {
      tmpZimFilePath.resize(tmpZimFilePath.size() - 2);
    }

    this->zimFileHandler = new zim::File(tmpZimFilePath);

    if (this->zimFileHandler != NULL) {
      this->firstArticleOffset = this->zimFileHandler->getNamespaceBeginOffset('A');
      this->lastArticleOffset = this->zimFileHandler->getNamespaceEndOffset('A');
      this->currentArticleOffset = this->firstArticleOffset;
      this->nsACount = this->zimFileHandler->getNamespaceCount('A');
      this->nsICount = this->zimFileHandler->getNamespaceCount('I');
    }

    /* initialize random seed: */
    srand ( time(NULL) );
  }

  /* Destructor */
  Reader::~Reader() {
    if (this->zimFileHandler != NULL) {
      delete this->zimFileHandler;
    }
  }

  zim::File* Reader::getZimFileHandler() {
    return this->zimFileHandler;
  }

  /* Reset the cursor for GetNextArticle() */
  void Reader::reset() {
    this->currentArticleOffset = this->firstArticleOffset;
  }

  std::map<std::string, unsigned int> Reader::parseCounterMetadata() {
    std::map<std::string, unsigned int> counters;
    string content, mimeType, item, counterString;
    unsigned int contentLength, counter;
    string counterUrl = "/M/Counter";

    this->getContentByUrl(counterUrl, content, contentLength, mimeType);
    stringstream ssContent(content);

    while(getline(ssContent, item,  ';')) {
      stringstream ssItem(item);
      getline(ssItem, mimeType, '=');
      getline(ssItem, counterString, '=');
      if (!counterString.empty() && !mimeType.empty()) {
	sscanf(counterString.c_str(), "%u", &counter);
	counters.insert(pair<string, int>(mimeType, counter));
      }
    }

    return counters;
  }

  /* Get the count of articles which can be indexed/displayed */
  unsigned int Reader::getArticleCount() {
    std::map<std::string, unsigned int> counterMap = this->parseCounterMetadata();
    unsigned int counter = 0;

    if (counterMap.empty()) {
      counter = this->nsACount;
    } else {
      std::map<std::string, unsigned int>::const_iterator it = counterMap.find("text/html");
      if (it != counterMap.end())
	counter = it->second;
    }

    return counter;
  }

  /* Get the count of medias content in the ZIM file */
  unsigned int Reader::getMediaCount() {
    std::map<std::string, unsigned int> counterMap = this->parseCounterMetadata();
    unsigned int counter = 0;

    if (counterMap.empty())
      counter = this->nsICount;
    else {
      std::map<std::string, unsigned int>::const_iterator it;

      it = counterMap.find("image/jpeg");
      if (it != counterMap.end())
	counter += it->second;

      it = counterMap.find("image/gif");
      if (it != counterMap.end())
	counter += it->second;

      it = counterMap.find("image/png");
      if (it != counterMap.end())
	counter += it->second;
    }

    return counter;
  }

  /* Get the total of all items of a ZIM file, redirects included */
  unsigned int Reader::getGlobalCount() {
    return this->zimFileHandler->getCountArticles();
  }

  /* Return the UID of the ZIM file */
  string Reader::getId() {
    std::ostringstream s;
    s << this->zimFileHandler->getFileheader().getUuid();
    return  s.str();
  }

  /* Return a page url from a title */
  bool Reader::getPageUrlFromTitle(const string &title, string &url) {
    /* Extract the content from the zim file */
    std::pair<bool, zim::File::const_iterator> resultPair = zimFileHandler->findxByTitle('A', title);

    /* Test if the article was found */
    if (resultPair.first == true) {

      /* Get the article */
      zim::Article article = *resultPair.second;

      /* If redirect */
      unsigned int loopCounter = 0;
      while (article.isRedirect() && loopCounter++<42) {
	article = article.getRedirectArticle();
      }

      url = article.getLongUrl();
      return true;
    }

    return false;
  }

  /* Return an URL from a title*/
  string Reader::getRandomPageUrl() {
    zim::Article article;
    zim::size_type idx;
    std::string mainPageUrl = this->getMainPageUrl();
    
    do {
      idx = this->firstArticleOffset +
	(zim::size_type)((double)rand() / ((double)RAND_MAX + 1) * this->nsACount);
      article = zimFileHandler->getArticle(idx);
    } while (article.getLongUrl() == mainPageUrl);

    return article.getLongUrl().c_str();
  }

  /* Return the welcome page URL */
  string Reader::getMainPageUrl() {
    string url = "";

    if (this->zimFileHandler->getFileheader().hasMainPage()) {
      zim::Article article = zimFileHandler->getArticle(this->zimFileHandler->getFileheader().getMainPage());
      url = article.getLongUrl();

      if (url.empty()) {
	url = getFirstPageUrl();
      }
    } else {
	url = getFirstPageUrl();
    }

    return url;
  }

  bool Reader::getFavicon(string &content, string &mimeType) {
    unsigned int contentLength = 0;

    this->getContentByUrl( "/-/favicon.png", content,
			   contentLength, mimeType);

    if (content.empty()) {
      this->getContentByUrl( "/I/favicon.png", content,
			     contentLength, mimeType);


      if (content.empty()) {
	this->getContentByUrl( "/I/favicon", content,
			       contentLength, mimeType);

	if (content.empty()) {
	  this->getContentByUrl( "/-/favicon", content,
				 contentLength, mimeType);
	}
      }
    }

    return content.empty() ? false : true;
  }

  /* Return a metatag value */
  bool Reader::getMetatag(const string &name, string &value) {
    unsigned int contentLength = 0;
    string contentType = "";

    return this->getContentByUrl( "/M/" + name, value,
				  contentLength, contentType);
  }

  string Reader::getTitle() {
    string value;
    this->getMetatag("Title", value);
    if (value.empty()) {
      value = getLastPathElement(zimFileHandler->getFilename());
      std::replace(value.begin(), value.end(), '_', ' ');
      size_t pos = value.find(".zim");
      value = value.substr(0, pos);
    }
    return value;
  }

  string Reader::getDescription() {
    string value;
    this->getMetatag("Description", value);

    /* Mediawiki Collection tends to use the "Subtitle" name */
    if (value.empty()) {
      this->getMetatag("Subtitle", value);
    }

    return value;
  }

  string Reader::getLanguage() {
    string value;
    this->getMetatag("Language", value);
    return value;
  }

  string Reader::getDate() {
    string value;
    this->getMetatag("Date", value);
    return value;
  }

  string Reader::getCreator() {
    string value;
    this->getMetatag("Creator", value);
    return value;
  }

  string Reader::getPublisher() {
    string value;
    this->getMetatag("Publisher", value);
    return value;
  }

  string Reader::getOrigId() {
    string value;
    this->getMetatag("startfileuid", value);
    if(value.empty())
        return "";
    std::string id=value;
    std::string origID;
    std::string temp="";
    unsigned int k=0;
    char tempArray[16]="";
    for(unsigned int i=0; i<id.size(); i++)
    {
        if(id[i]=='\n')
        {
            tempArray[k]= atoi(temp.c_str());
            temp="";
            k++;
        }
        else
        {
            temp+=id[i];
        }
    }
    origID=hexUUID(tempArray);
    return origID;
  }

  /* Return the first page URL */
  string Reader::getFirstPageUrl() {
    string url;

    zim::size_type firstPageOffset = zimFileHandler->getNamespaceBeginOffset('A');
    zim::Article article = zimFileHandler->getArticle(firstPageOffset);
    url = article.getLongUrl();

    return url;
  }

  bool Reader::parseUrl(const string &url, char *ns, string &title) {
    /* Offset to visit the url */
    unsigned int urlLength = url.size();
    unsigned int offset = 0;

    /* Ignore the '/' */
    while ((offset < urlLength) && (url[offset] == '/')) offset++;

    /* Get namespace */
    while ((offset < urlLength) && (url[offset] != '/')) {
      *ns= url[offset];
      offset++;
    }

    /* Ignore the '/' */
    while ((offset < urlLength) && (url[offset] == '/')) offset++;

    /* Get content title */
    unsigned int titleOffset = offset;
    while (offset < urlLength) {
      offset++;
    }

    /* unescape title */
    title = url.substr(titleOffset, offset - titleOffset);

    return true;
  }

  /* Return article by url */
  bool Reader::getArticleObjectByDecodedUrl(const string &url, zim::Article &article) {
    bool retVal = false;
    
    if (this->zimFileHandler != NULL) {
      
      /* Parse the url */
      char ns = 0;
      string titleStr;
      this->parseUrl(url, &ns, titleStr);
      
      /* Main page */
      if (titleStr.empty() && ns == 0) {
	this->parseUrl(this->getMainPageUrl(), &ns, titleStr);
      }
      
      /* Extract the content from the zim file */
      std::pair<bool, zim::File::const_iterator> resultPair = zimFileHandler->findx(ns, titleStr);
      
      /* Test if the article was found */
      if (resultPair.first == true) {
	article = zimFileHandler->getArticle(resultPair.second.getIndex());
	retVal = true;
      }

    }
    
    return retVal;
  }

  /* Return the mimeType without the content */
  bool Reader::getMimeTypeByUrl(const string &url, string &mimeType) {
    bool retVal = false;

    if (this->zimFileHandler != NULL) {

      zim::Article article;
      if (this->getArticleObjectByDecodedUrl(url, article)) {
	  try {
	    mimeType = string(article.getMimeType().data(), article.getMimeType().size());
	  } catch (exception &e) {
	    cerr << "Unable to get the mimetype for "<< url << ":" << e.what() << endl;
	    mimeType = "application/octet-stream";
	  }	
	  retVal = true;
      } else {
	mimeType = "";
      }
     
    }

    return retVal;
  }

  /* Get a content from a zim file */
  bool Reader::getContentByUrl(const string &url, string &content, unsigned int &contentLength, string &contentType) {
    return this->getContentByEncodedUrl(url, content, contentLength, contentType);
  }

  bool Reader::getContentByEncodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType, string &baseUrl) {
    return this->getContentByDecodedUrl(kiwix::urlDecode(url), content, contentLength, contentType, baseUrl);
  }

  bool Reader::getContentByEncodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType) {
    std::string stubRedirectUrl;
    return this->getContentByEncodedUrl(kiwix::urlDecode(url), content, contentLength, contentType, stubRedirectUrl); 
  }

  bool Reader::getContentByDecodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType) {
    std::string stubRedirectUrl;
    return this->getContentByDecodedUrl(kiwix::urlDecode(url), content, contentLength, contentType, stubRedirectUrl);
  }

  bool Reader::getContentByDecodedUrl(const string &url, string &content, unsigned int &contentLength, string &contentType, string &baseUrl) {
    bool retVal = false;
    content="";
    contentType="";
    contentLength = 0;
    if (this->zimFileHandler != NULL) {

      zim::Article article;
      if (this->getArticleObjectByDecodedUrl(url, article)) {
	
	/* If redirect */
	unsigned int loopCounter = 0;
	while (article.isRedirect() && loopCounter++<42) {
	  article = article.getRedirectArticle();
	}

	if (loopCounter < 42) {
	  /* Compute base url (might be different from the url if redirects */
	  baseUrl = "/" + std::string(1, article.getNamespace()) + "/" + article.getUrl();
	  
	  /* Get the content mime-type */
	  try {
	    contentType = string(article.getMimeType().data(), article.getMimeType().size());
	  } catch (exception &e) {
	    cerr << "Unable to get the mimetype for "<< baseUrl<< ":" << e.what() << endl;
	    contentType = "application/octet-stream";
	  }

	  /* Get the data */
	  content = string(article.getData().data(), article.getArticleSize());
	}

	/* Try to set a stub HTML header/footer if necesssary */
	if (contentType.find("text/html") != string::npos && 
	    content.find("<body") == std::string::npos &&
	    content.find("<BODY") == std::string::npos) {
	  content = "<html><head><title>" + article.getTitle() + "</title><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" /></head><body>" + content + "</body></html>";
	}

	/* Get the data length */
	contentLength = article.getArticleSize();

	/* Set return value */
	retVal = true;
      }
    }

    return retVal;
  }

  /* Search titles by prefix */
  bool Reader::searchSuggestions(const string &prefix, unsigned int suggestionsCount, const bool reset) {
    bool retVal = false;
    zim::File::const_iterator articleItr;

    /* Reset the suggestions otherwise check if the suggestions number is less than the suggestionsCount */
    if (reset) {
      this->suggestions.clear();
      this->suggestionsOffset = this->suggestions.begin();
    } else {
      if (this->suggestions.size() > suggestionsCount) {
	return false;
      }
    }

    /* Return if no prefix */
    if (prefix.size() == 0) {
      return false;
    }

    for (articleItr = zimFileHandler->findByTitle('A', prefix);
	 articleItr != zimFileHandler->end() &&
	   articleItr->getTitle().compare(0, prefix.size(), prefix) == 0 &&
	   this->suggestions.size() < suggestionsCount ;
	 ++articleItr) {

      /* Extract the interesting part of article title & url */
      std::string normalizedArticleTitle = kiwix::normalize(articleItr->getTitle());
      std::string articleFinalUrl = "/A/"+articleItr->getUrl();
      if (articleItr->isRedirect()) {
	zim::Article article = *articleItr;
	unsigned int loopCounter = 0;
	while (article.isRedirect() && loopCounter++<42) {
	  article = article.getRedirectArticle();
	}
	articleFinalUrl = "/A/"+article.getUrl();
      }

      /* Go through all already found suggestions and skip if this
	 article is already in the suggestions list (with an other
	 title) */
      bool insert = true;
      std::vector< std::vector<std::string> >::iterator suggestionItr;
      for (suggestionItr = this->suggestions.begin(); suggestionItr != this->suggestions.end(); suggestionItr++) {
	int result = normalizedArticleTitle.compare((*suggestionItr)[2]);
	if (result == 0 && articleFinalUrl.compare((*suggestionItr)[1]) == 0) {
	  insert = false;
	  break;
	} else if (result < 0) {
	  break;
	}
      }

      /* Insert if possible */
      if (insert) {
	std::vector<std::string> suggestion;
	suggestion.push_back(articleItr->getTitle());
	suggestion.push_back(articleFinalUrl);
	suggestion.push_back(normalizedArticleTitle);
	this->suggestions.insert(suggestionItr, suggestion);
      }

      /* Suggestions where found */
      retVal = true;
    }

    /* Set the cursor to the begining */
    this->suggestionsOffset = this->suggestions.begin();

    return retVal;
  }

  std::vector<std::string> Reader::getTitleVariants(const std::string &title) {
    std::vector<std::string> variants;
    variants.push_back(title);
    variants.push_back(kiwix::ucFirst(title));
    variants.push_back(kiwix::lcFirst(title));
    variants.push_back(kiwix::toTitle(title));
    return variants;
  }

  /* Try also a few variations of the prefix to have better results */
  bool Reader::searchSuggestionsSmart(const string &prefix, unsigned int suggestionsCount) {
    std::vector<std::string> variants = this->getTitleVariants(prefix);
    bool retVal;
    
    this->suggestions.clear();
    this->suggestionsOffset = this->suggestions.begin();
    for (std::vector<std::string>::iterator variantsItr = variants.begin();
	 variantsItr != variants.end();
	 variantsItr++) {
      retVal = this->searchSuggestions(*variantsItr, suggestionsCount, false) || retVal;
    }

    return retVal;
  }

  /* Get next suggestion */
  bool Reader::getNextSuggestion(string &title) {
    if (this->suggestionsOffset != this->suggestions.end()) {
      /* title */
      title = (*(this->suggestionsOffset))[0];

      /* increment the cursor for the next call */
      this->suggestionsOffset++;

      return true;
    }

    return false;
  }

  bool Reader::getNextSuggestion(string &title, string &url) {
    if (this->suggestionsOffset != this->suggestions.end()) {
      /* title */
      title = (*(this->suggestionsOffset))[0];
      url = (*(this->suggestionsOffset))[1];

      /* increment the cursor for the next call */
      this->suggestionsOffset++;

      return true;
    }

    return false;
  }

  /* Check if the file has as checksum */
  bool Reader::canCheckIntegrity() {
    return this->zimFileHandler->getChecksum() != "";
  }

  /* Return true if corrupted, false otherwise */
  bool Reader::isCorrupted() {
    try {
      if (this->zimFileHandler->verify() == true)
	return false;
    } catch (exception &e) {
      cerr << e.what() << endl;
      return true;
    }

    return true;
  }

  /* Return the file size, works also for splitted files */
  unsigned int Reader::getFileSize() {
    zim::File *file = this->getZimFileHandler();
    zim::offset_type size = 0;

    if (file != NULL) {
      size = file->getFilesize();
    }

    return (size / 1024);
  }
}
