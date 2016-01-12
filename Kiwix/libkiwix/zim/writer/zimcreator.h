/*
 * Copyright (C) 2009 Tommi Maekitalo
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

#ifndef ZIM_WRITER_ZIMCREATOR_H
#define ZIM_WRITER_ZIMCREATOR_H

#include <zim/writer/articlesource.h>
#include <zim/writer/dirent.h>
#include <vector>
#include <map>

namespace zim
{
  namespace writer
  {
    class ZimCreator
    {
      public:
        typedef std::vector<Dirent> DirentsType;
        typedef std::vector<size_type> SizeVectorType;
        typedef std::vector<offset_type> OffsetsType;
        typedef std::map<std::string, uint16_t> MimeTypes;
        typedef std::map<uint16_t, std::string> RMimeTypes;

      private:
        unsigned minChunkSize;

        Fileheader header;

        DirentsType dirents;
        SizeVectorType titleIdx;
        OffsetsType clusterOffsets;
        MimeTypes mimeTypes;
        RMimeTypes rmimeTypes;
        uint16_t nextMimeIdx;
        CompressionType compression;
        bool isEmpty;
        offset_type clustersSize;

        void createDirents(ArticleSource& src);
        void createTitleIndex(ArticleSource& src);
        void createClusters(ArticleSource& src, const std::string& tmpfname);
        void fillHeader(ArticleSource& src);
        void write(const std::string& fname, const std::string& tmpfname);

        size_type clusterCount() const        { return clusterOffsets.size(); }
        size_type articleCount() const        { return dirents.size(); }
        offset_type mimeListSize() const;
        offset_type mimeListPos() const       { return Fileheader::size; }
        offset_type urlPtrSize() const        { return articleCount() * sizeof(offset_type); }
        offset_type urlPtrPos() const         { return mimeListPos() + mimeListSize(); }
        offset_type titleIdxSize() const      { return articleCount() * sizeof(size_type); }
        offset_type titleIdxPos() const       { return urlPtrPos() + urlPtrSize(); }
        offset_type indexSize() const;
        offset_type indexPos() const          { return titleIdxPos() + titleIdxSize(); }
        offset_type clusterPtrSize() const    { return clusterCount() * sizeof(offset_type); }
        offset_type clusterPtrPos() const     { return indexPos() + indexSize(); }
        offset_type checksumPos() const       { return clusterPtrPos() + clusterPtrSize() + clustersSize; }

        uint16_t getMimeTypeIdx(const std::string& mimeType);
        const std::string& getMimeType(uint16_t mimeTypeIdx) const;

      public:
        ZimCreator();
        ZimCreator(int& argc, char* argv[]);

        unsigned getMinChunkSize()    { return minChunkSize; }
        void setMinChunkSize(int s)   { minChunkSize = s; }

        void create(const std::string& fname, ArticleSource& src);
    };

  }

}

#endif // ZIM_WRITER_ZIMCREATOR_H
