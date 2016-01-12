/*
 * Copyright (C) 2006 Tommi Maekitalo
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * is provided AS IS, WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, and
 * NON-INFRINGEMENT.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 *
 */

#ifndef ZIM_DIRENT_H
#define ZIM_DIRENT_H

#include <string>
#include <zim/zim.h>

namespace zim
{
  class Dirent
  {
      uint16_t mimeType;

      size_type version;

      size_type clusterNumber;  // only used when redirect is false
      size_type blobNumber;    // only used when redirect is false

      size_type redirectIndex;  // only used when redirect is true

      char ns;
      std::string title;
      std::string url;
      std::string parameter;

    public:
      // these constants are put into mimeType field
      static const uint16_t redirectMimeType = 0xffff;
      static const uint16_t linktargetMimeType = 0xfffe;
      static const uint16_t deletedMimeType = 0xfffd;

      Dirent()
        : mimeType(0),
          version(0),
          clusterNumber(0),
          blobNumber(0),
          redirectIndex(0),
          ns('\0')
      {}

      bool isRedirect() const                 { return mimeType == redirectMimeType; }
      bool isLinktarget() const               { return mimeType == linktargetMimeType; }
      bool isDeleted() const                  { return mimeType == deletedMimeType; }
      bool isArticle() const                  { return !isRedirect() && !isLinktarget() && !isDeleted(); }
      uint16_t getMimeType() const            { return mimeType; }

      size_type getVersion() const            { return version; }
      void setVersion(size_type v)            { version = v; }

      size_type getClusterNumber() const      { return isRedirect() ? 0 : clusterNumber; }
      size_type getBlobNumber() const         { return isRedirect() ? 0 : blobNumber; }
      void setCluster(size_type clusterNumber_, size_type blobNumber_)
        { clusterNumber = clusterNumber_; blobNumber = blobNumber_; }

      size_type getRedirectIndex() const      { return isRedirect() ? redirectIndex : 0; }

      char getNamespace() const               { return ns; }
      const std::string& getTitle() const     { return title.empty() ? url : title; }
      const std::string& getUrl() const       { return url; }
      std::string getLongUrl() const;
      const std::string& getParameter() const { return parameter; }

      unsigned getDirentSize() const
      {
        // MODIFY
        //unsigned ret = (isRedirect() ? 12 : 16) + url.size() + parameter.size() + 2;
        unsigned ret = (isRedirect() ? 12 : 16) + (int)url.size() + (int)parameter.size() + 2;
        if (title != url)
          ret += title.size();
        return ret;
      }

      void setTitle(const std::string& title_)
      {
        title = title_;
      }

      void setUrl(char ns_, const std::string& url_)
      {
        ns = ns_;
        url = url_;
      }

      void setParameter(const std::string& parameter_)
      {
        parameter = parameter_;
      }

      void setRedirect(size_type idx)
      {
        redirectIndex = idx;
        mimeType = redirectMimeType;
        clusterNumber = 0;
        blobNumber = 0;
      }

      void setMimeType(uint16_t mime)
      {
        mimeType = mime;
      }

      void setLinktarget()
      {
        mimeType = linktargetMimeType;
        clusterNumber = 0;
        blobNumber = 0;
      }

      void setDeleted()
      {
        mimeType = deletedMimeType;
        clusterNumber = 0;
        blobNumber = 0;
      }

      void setArticle(uint16_t mimeType_, size_type clusterNumber_, size_type blobNumber_)
      {
        mimeType = mimeType_;
        clusterNumber = clusterNumber_;
        blobNumber = blobNumber_;
      }

  };

  std::ostream& operator<< (std::ostream& out, const Dirent& fh);
  std::istream& operator>> (std::istream& in, Dirent& fh);

}

#endif // ZIM_DIRENT_H

