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

#include "xapianSearcher.h"

namespace kiwix {

  /* Constructor */
  XapianSearcher::XapianSearcher(const string &xapianDirectoryPath) 
    : Searcher(),
      stemmer(Xapian::Stem("english")) {
    this->openIndex(xapianDirectoryPath);
  }

  /* Open Xapian readable database */
  void XapianSearcher::openIndex(const string &directoryPath) {
    this->readableDatabase = Xapian::Database(directoryPath);
  }
  
  /* Close Xapian writable database */
  void XapianSearcher::closeIndex() {
    return;
  }
  
  /* Search strings in the database */
  void XapianSearcher::searchInIndex(string &search, const unsigned int resultStart, 
				     const unsigned int resultEnd, const bool verbose) {
    /* Create the query */
    Xapian::QueryParser queryParser;
    Xapian::Query query = queryParser.parse_query(search);    

    /* Create the enquire object */
    Xapian::Enquire enquire(this->readableDatabase);
    enquire.set_query(query);

    /* Get the results */
    Xapian::MSet matches = enquire.get_mset(resultStart, resultEnd - resultStart);
    
    Xapian::MSetIterator i;
    for (i = matches.begin(); i != matches.end(); ++i) {
      Xapian::Document doc = i.get_document();
      
      Result result;
      result.url = doc.get_data();
      result.title = doc.get_value(0);
      result.snippet = doc.get_value(1);
      result.size = (doc.get_value(2).empty() == true ? -1 : atoi(doc.get_value(2).c_str()));
      result.wordCount = (doc.get_value(3).empty() == true ? -1 : atoi(doc.get_value(3).c_str()));
      result.score = i.get_percent();
      
      this->results.push_back(result);

      if (verbose) {
	std::cout << "Document ID " << *i << "   \t";
	std::cout << i.get_percent() << "% ";
	std::cout << "\t[" << doc.get_data() << "] - " << doc.get_value(0) << std::endl;
      }
    }

    /* Update the global resultCount value*/
    this->estimatedResultCount = matches.get_matches_estimated();

    return;
  }
}
