# Annotated log
#
# Note that this log has been fudged:
#
#   + The Date headers and _lastModified timestamps for carts were
#     fudged from an earlier run.
#
#   + The 204 NO CONTENT HTTP status codes were fudged.

# start server in background
# specifying data file, all carts and books are cleared and books reloaded
# from data file
$ ./index.mjs 2345 mongodb://localhost:27017/books \
     ~/cs544/data/2000-books.json.gz &
[1] 700672  #bash prints job # and PID
$ 700672    #server prints its PID
listening on port 2345  #I typed a return here to get a shell prompt

# hit /api (only published URL); shows links to supported services
# -X specified HTTP method (not necessary in this case as default is GET)
# -s makes curl silent and prevents it from printing progress indicators
# -D /dev/stderr dumps response headers to stderr
# stdout of curl piped into json_pp to pretty-print json response
$ curl -X GET -s -D /dev/stderr http://localhost:2345/api | json_pp
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 229
ETag: W/"e5-4/Ez86ruuNr7RnTR3Hmt4AOGJDw"
Date: Sun, 12 Jul 2020 15:48:25 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api",
         "name" : "self",
         "rel" : "self"
      },
      {
         "href" : "http://localhost:2345/api/books",
         "name" : "books",
         "rel" : "collection"
      },
      {
         "href" : "http://localhost:2345/api/carts",
         "name" : "carts",
         "rel" : "collection"
      }
   ]
}

# go to books url: need to specify at least one search field
$ curl -X GET -s -D /dev/stderr http://localhost:2345/api/books | json_pp
HTTP/1.1 400 Bad Request
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 114
ETag: W/"72-LwbBCa73LKli6S4rz6ua66aaxDs"
Date: Sun, 12 Jul 2020 15:51:42 GMT
Connection: keep-alive

{
   "errors" : [
      {
         "code" : "FORM_ERROR",
         "message" : "At least one search field must be specified.",
         "name" : ""
      }
   ],
   "status" : 400
}

# look for Bliss books; should be exactly 3 such books in synthetic data
$ curl -X GET -s -D /dev/stderr \
    http://localhost:2345/api/books?authorsTitleSearch=bliss | json_pp
> HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 1013
ETag: W/"3f5-hrT+ZDqXFGrPWL7QXXCy4nDy4pI"
Date: Sun, 12 Jul 2020 15:51:55 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=bliss",
         "name" : "self",
         "rel" : "self"
      }
   ],
   "result" : [
      {
         "_lastModified" : "2020-07-12T15:47:58.291Z",
         "authors" : [
            "Wolfkeil, Joey",
            "Tharp, Yessenia"
         ],
         "isbn" : "735-411-209-1",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/735-411-209-1",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 303,
         "publisher" : "Prentice-Hall",
         "title" : "Basics of Bliss Programming",
         "year" : 2014
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.679Z",
         "authors" : [
            "Valenzuela, Mario",
            "Wolk, Katelin"
         ],
         "isbn" : "783-408-420-2",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/783-408-420-2",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 425,
         "publisher" : "Pearson",
         "title" : "Fundamentals of Bliss Programming",
         "year" : 2004
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.776Z",
         "authors" : [
            "Anderson, Yair",
            "Jamar, Joey"
         ],
         "isbn" : "758-807-384-9",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/758-807-384-9",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 520,
         "publisher" : "Manning",
         "title" : "The Idiot's Guide to Bliss",
         "year" : 2007
      }
   ]
}

# show only last Bliss book, no next link
$ curl -s -D /dev/stderr \
  'http://localhost:2345/api/books?authorsTitleSearch=bliss&_index=2&_count=1' \
  | json_pp
> > HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 539
ETag: W/"21b-WcLbtFQYKxc+zHp7AhZtNSe1770"
Date: Sun, 12 Jul 2020 15:52:11 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=bliss&_index=2&_count=1",
         "name" : "self",
         "rel" : "self"
      },
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=bliss&_index=1&_count=1",
         "name" : "prev",
         "rel" : "prev"
      }
   ],
   "result" : [
      {
         "_lastModified" : "2020-07-12T15:47:58.776Z",
         "authors" : [
            "Anderson, Yair",
            "Jamar, Joey"
         ],
         "isbn" : "758-807-384-9",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/758-807-384-9",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 520,
         "publisher" : "Manning",
         "title" : "The Idiot's Guide to Bliss",
         "year" : 2007
      }
   ]
}

# show 2nd Bliss book, has both next and prev links
$ curl -s -D /dev/stderr \
  'http://localhost:2345/api/books?authorsTitleSearch=bliss&_index=1&_count=1' \
  | json_pp
> > HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 664
ETag: W/"298-xVSOMa7tzSi5xGV1qBk84DfvF3g"
Date: Sun, 12 Jul 2020 15:53:54 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=bliss&_index=1&_count=1",
         "name" : "self",
         "rel" : "self"
      },
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=bliss&_index=2&_count=1",
         "name" : "next",
         "rel" : "next"
      },
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=bliss&_index=0&_count=1",
         "name" : "prev",
         "rel" : "prev"
      }
   ],
   "result" : [
      {
         "_lastModified" : "2020-07-12T15:47:58.679Z",
         "authors" : [
            "Valenzuela, Mario",
            "Wolk, Katelin"
         ],
         "isbn" : "783-408-420-2",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/783-408-420-2",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 425,
         "publisher" : "Pearson",
         "title" : "Fundamentals of Bliss Programming",
         "year" : 2004
      }
   ]
}

# look for COBOL books; should be exactly 5 such books in synthetic data
# no prev or next links
# note results are sorted in ascending order by title
$ curl -s -D /dev/stderr \
  'http://localhost:2345/api/books?authorsTitleSearch=cobol' | json_pp
> HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 1661
ETag: W/"67d-0ar1mfztkzE+JJcgy2iM2Rx8Z88"
Date: Sun, 12 Jul 2020 15:54:05 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=cobol",
         "name" : "self",
         "rel" : "self"
      }
   ],
   "result" : [
      {
         "_lastModified" : "2020-07-12T15:47:58.386Z",
         "authors" : [
            "Wrobel, Luis",
            "Waalen, Adriane"
         ],
         "isbn" : "091-809-332-4",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/091-809-332-4",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 411,
         "publisher" : "Pearson",
         "title" : "Basics of COBOL Programming",
         "year" : 2006
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.440Z",
         "authors" : [
            "Atkins, Johan"
         ],
         "isbn" : "858-000-380-7",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/858-000-380-7",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 127,
         "publisher" : "Addison-Wesley",
         "title" : "COBOL Programmers Reference",
         "year" : 2004
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.675Z",
         "authors" : [
            "Edmonds, Tiara",
            "Rich, Yasmine",
            "Wiegand, Sarah",
            "Wunder, Landon"
         ],
         "isbn" : "688-975-858-4",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/688-975-858-4",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 81,
         "publisher" : "O'Reilly",
         "title" : "COBOL Reference Manual",
         "year" : 2002
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.773Z",
         "authors" : [
            "Vine-Gar, Sebastian",
            "Sanon, Raequan",
            "Caffey, Makala",
            "Batten, Joshua"
         ],
         "isbn" : "869-516-122-5",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/869-516-122-5",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 150,
         "publisher" : "O'Reilly",
         "title" : "Fundamentals of COBOL Programming",
         "year" : 2012
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.776Z",
         "authors" : [
            "Wennes, Eileen",
            "Warmsley, Neftaly"
         ],
         "isbn" : "943-517-006-4",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/943-517-006-4",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 96,
         "publisher" : "Prentice-Hall",
         "title" : "The Idiot's Guide to COBOL",
         "year" : 2009
      }
   ]
}

# look for D books; should be exactly 6 such books in synthetic data
# no prev link but has a next link
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/books?authorsTitleSearch=d' | json_pp
> HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 1713
ETag: W/"6b1-/kdvKbsKpoeCtL7L22esw53eDdE"
Date: Sun, 12 Jul 2020 15:54:25 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=d",
         "name" : "self",
         "rel" : "self"
      },
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=d&_index=5",
         "name" : "next",
         "rel" : "next"
      }
   ],
   "result" : [
      {
         "_lastModified" : "2020-07-12T15:47:58.436Z",
         "authors" : [
            "Tharp, Yessenia"
         ],
         "isbn" : "818-644-973-1",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/818-644-973-1",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 99,
         "publisher" : "O'Reilly",
         "title" : "Basics of D Programming",
         "year" : 2001
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.569Z",
         "authors" : [
            "Woodford, Alfredo",
            "Chavez, Lindsay",
            "Wolfkeil, Joey"
         ],
         "isbn" : "587-415-971-1",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/587-415-971-1",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 577,
         "publisher" : "Pearson",
         "title" : "D Programmers Reference",
         "year" : 2016
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.443Z",
         "authors" : [
            "Doubt, Aubrie",
            "Evenski, Rhett",
            "Gandy, Henry"
         ],
         "isbn" : "198-190-051-4",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/198-190-051-4",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 428,
         "publisher" : "Prentice-Hall",
         "title" : "D Reference Manual",
         "year" : 2008
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.630Z",
         "authors" : [
            "Alferez, Kaden",
            "Fenton, Amelia",
            "Weest, Dalton",
            "Dildy, Brandy"
         ],
         "isbn" : "718-569-364-8",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/718-569-364-8",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 187,
         "publisher" : "Addison-Wesley",
         "title" : "D: The Good Parts",
         "year" : 2004
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.696Z",
         "authors" : [
            "Wysel, Kaytlin"
         ],
         "isbn" : "100-024-008-6",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/100-024-008-6",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 555,
         "publisher" : "New Starch",
         "title" : "Fundamentals of D Programming",
         "year" : 2016
      }
   ]
}

# look for next 5 D books, only 1 book returned with no next link
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/books?authorsTitleSearch=d&_index=5' | json_pp
> HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 551
ETag: W/"227-k2GB2sTzcK9pqHwz2h/KEQmKk8c"
Date: Sun, 12 Jul 2020 15:54:44 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=d&_index=5",
         "name" : "self",
         "rel" : "self"
      },
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=d&_index=0",
         "name" : "prev",
         "rel" : "prev"
      }
   ],
   "result" : [
      {
         "_lastModified" : "2020-07-12T15:47:58.632Z",
         "authors" : [
            "Wadley, Joan",
            "Duran, Kristyn",
            "Wielinski, Zenia",
            "Sigala, Tamia"
         ],
         "isbn" : "101-902-716-6",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/101-902-716-6",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 377,
         "publisher" : "Prentice-Hall",
         "title" : "The Idiot's Guide to D",
         "year" : 2014
      }
   ]
}

# synthetic data has exactly 11 Go books; look at last 3, no next link
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/books?authorsTitleSearch=go&_index=8' | json_pp
> HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 1142
ETag: W/"476-wr7oRHdCDM770kwwA7zBGulrNMc"
Date: Sun, 12 Jul 2020 15:54:56 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=go&_index=8",
         "name" : "self",
         "rel" : "self"
      },
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=go&_index=3",
         "name" : "prev",
         "rel" : "prev"
      }
   ],
   "result" : [
      {
         "_lastModified" : "2020-07-12T15:47:58.694Z",
         "authors" : [
            "Craft, Kaili",
            "Widen, Caitlan"
         ],
         "isbn" : "349-377-401-2",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/349-377-401-2",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 221,
         "publisher" : "Manning",
         "title" : "Intermediate Go Programming",
         "year" : 2008
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.470Z",
         "authors" : [
            "Futrell, Gunnar",
            "Calder, Sade"
         ],
         "isbn" : "153-874-482-8",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/153-874-482-8",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 434,
         "publisher" : "New Starch",
         "title" : "Programming in Go",
         "year" : 2002
      },
      {
         "_lastModified" : "2020-07-12T15:47:58.303Z",
         "authors" : [
            "Ackley, Angel",
            "Wielinski, Zenia",
            "Batten, Marycather",
            "Ransome, Annalie"
         ],
         "isbn" : "732-339-628-9",
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/732-339-628-9",
               "name" : "book",
               "rel" : "details"
            }
         ],
         "pages" : 371,
         "publisher" : "Prentice-Hall",
         "title" : "The Idiot's Guide to Go",
         "year" : 2019
      }
   ]
}

# no results is not an error, merely empty results
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/books?authorsTitleSearch=xxx' | json_pp
> HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 116
ETag: W/"74-oypIe/qPj1hd+Mw9DnJiyPWZNJ4"
Date: Sun, 12 Jul 2020 15:55:15 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books?authorsTitleSearch=xxx",
         "name" : "self",
         "rel" : "self"
      }
   ],
   "result" : []
}

# fetch specific book
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/books/732-339-628-9' | json_pp
> HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 345
ETag: W/"159-ZAqL+LE1a8h6EwrHUM8JiCer634"
Date: Sun, 12 Jul 2020 15:55:29 GMT
Connection: keep-alive

{
   "links" : [
      {
         "href" : "http://localhost:2345/api/books/732-339-628-9",
         "name" : "self",
         "rel" : "self"
      }
   ],
   "result" : {
      "_lastModified" : "2020-07-12T15:47:58.303Z",
      "authors" : [
         "Ackley, Angel",
         "Wielinski, Zenia",
         "Batten, Marycather",
         "Ransome, Annalie"
      ],
      "isbn" : "732-339-628-9",
      "pages" : 371,
      "publisher" : "Prentice-Hall",
      "title" : "The Idiot's Guide to Go",
      "year" : 2019
   }
}

# 404 if book not found
$ curl -X GET -s -D /dev/stderr \
   'http://localhost:2345/api/books/732-339-628-99' | json_pp
> HTTP/1.1 404 Not Found
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 101
ETag: W/"65-pFGolsk42BxVutzL8tZEQcQ31JQ"
Date: Sun, 12 Jul 2020 15:56:04 GMT
Connection: keep-alive

{
   "errors" : [
      {
         "code" : "BAD_ID",
         "message" : "no book for isbn 732-339-628-99",
         "name" : "isbn"
      }
   ],
   "status" : 404
}

# bad isbn
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/books/732-339-628-9x' | json_pp
> HTTP/1.1 400 Bad Request
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 178
ETag: W/"b2-jXnZ5Kn29udlyUv3kpqBEZh01PE"
Date: Sun, 12 Jul 2020 15:56:30 GMT
Connection: keep-alive

{
   "errors" : [
      {
         "code" : "BAD_FIELD_VALUE",
         "message" : "bad value: \"732-339-628-9x\": The ISBN field must consists of one-or-more digits separated by '-'.",
         "name" : "isbn"
      }
   ],
   "status" : 400
}

################################ Carts ##################################

# no GET to carts url
$ curl -X GET -s -D /dev/stderr 'http://localhost:2345/api/carts' | json_pp
HTTP/1.1 404 Not Found
X-Powered-By: Express
Content-Type: text/plain; charset=utf-8
Content-Length: 91
ETag: W/"5b-B9Kvc7BLIULWSZAVC/UXFHnZqRI"
Date: Sun, 12 Jul 2020 15:57:02 GMT
Connection: keep-alive

{
   "errors" : [
      {
         "code" : "NOT_FOUND",
         "message" : "GET not supported for /api/carts"
      }
   ],
   "status" : 404
}

# create a new cart: Location header gives URL of new cart
$ curl -X POST -s -D /dev/stderr 'http://localhost:2345/api/carts' 
HTTP/1.1 201 Created
X-Powered-By: Express
Location: http://localhost:2345/api/carts/0.24182330731217916
Date: Sun, 12 Jul 2020 15:57:20 GMT
Connection: keep-alive
Content-Length: 0

# list contents of newly created cart
$ curl -X GET -s -D /dev/stderr 'http://localhost:2345/api/carts/0.24182330731217916' | json_pp
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 156
ETag: W/"9c-pVR2znhfQ5rhBwH+4Rvm83IfHdc"
Date: Sun, 12 Jul 2020 15:57:40 GMT
Connection: keep-alive

{
   "_lastModified" : "2020-07-12T15:57:20.059Z",
   "links" : [
      {
         "href" : "http://localhost:2345/api/carts/0.24182330731217916",
         "name" : "self",
         "rel" : "self"
      }
   ],
   "result" : []
}

# add 2 units of a book to cart
# -H sends Content-Type header and -d sets (json) data for body
$ curl -X PATCH -s -D /dev/stderr \
  'http://localhost:2345/api/carts/0.24182330731217916' \
  -H 'Content-Type: application/json' \
  -d '{ "sku": "732-339-628-9", "nUnits": 2 }'
HTTP/1.1 204 No Content
X-Powered-By: Express
Date: Sun, 12 Jul 2020 15:58:00 GMT
Connection: keep-alive

# add 3 units of another book to cart
$ curl -X PATCH -s -D /dev/stderr \
    'http://localhost:2345/api/carts/0.24182330731217916' \
    -H 'Content-Type: application/json' \
    -d '{ "sku": "349-377-401-2", "nUnits": 3 }'
HTTP/1.1 204 No Content
X-Powered-By: Express
Date: Sun, 12 Jul 2020 15:58:15 GMT
Connection: keep-alive

# display cart
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/carts/0.24182330731217916' | json_pp
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 413
ETag: W/"19d-uBTsIAR02u9+r7ygZy4Lztm8EbA"
Date: Sun, 12 Jul 2020 15:58:22 GMT
Connection: keep-alive

{
   "_lastModified" : "2020-07-12T15:58:15.774Z",
   "links" : [
      {
         "href" : "http://localhost:2345/api/carts/0.24182330731217916",
         "name" : "self",
         "rel" : "self"
      }
   ],
   "result" : [
      {
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/732-339-628-9",
               "name" : "book",
               "rel" : "item"
            }
         ],
         "nUnits" : 2,
         "sku" : "732-339-628-9"
      },
      {
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/349-377-401-2",
               "name" : "book",
               "rel" : "item"
            }
         ],
         "nUnits" : 3,
         "sku" : "349-377-401-2"
      }
   ]
}

# remove book by setting nUnits to 0
$ curl -X PATCH -s -D /dev/stderr \
    'http://localhost:2345/api/carts/0.24182330731217916' \
    -H 'Content-Type: application/json' \
    -d '{ "sku": "349-377-401-2", "nUnits": 0 }'
HTTP/1.1 204 No Content
X-Powered-By: Express
Date: Sun, 12 Jul 2020 15:58:30 GMT
Connection: keep-alive

# display updated cart
$ curl -X GET -s -D /dev/stderr \
    'http://localhost:2345/api/carts/0.24182330731217916' | json_pp
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 284
ETag: W/"11c-Z6zeCnsustK22u5lU4agOGp7EGs"
Date: Sun, 12 Jul 2020 15:58:45 GMT
Connection: keep-alive

{
   "_lastModified" : "2020-07-12T15:58:30.820Z",
   "links" : [
      {
         "href" : "http://localhost:2345/api/carts/0.24182330731217916",
         "name" : "self",
         "rel" : "self"
      }
   ],
   "result" : [
      {
         "links" : [
            {
               "href" : "http://localhost:2345/api/books/732-339-628-9",
               "name" : "book",
               "rel" : "item"
            }
         ],
         "nUnits" : 2,
         "sku" : "732-339-628-9"
      }
   ]
}

#add non-existent book
$ curl -X PATCH -s -D /dev/stderr \
    'http://localhost:2345/api/carts/0.24182330731217916' \
    -H 'Content-Type: application/json' \
    -d '{ "sku": "349-377-401-23", "nUnits": 5 }' | json_pp
HTTP/1.1 404 Not Found
X-Powered-By: Express
Content-Type: application/json; charset=utf-8
Content-Length: 95
ETag: W/"5f-uL621V7yPLKYZNqPaFequiefjH0"
Date: Sun, 12 Jul 2020 15:59:00 GMT
Connection: keep-alive

{
   "errors" : [
      {
         "code" : "BAD_ID",
         "message" : "unknown sku 349-377-401-23",
         "name" : "sku"
      }
   ],
   "status" : 404
}

# put background server into foreground
$ fg
./index.mjs 2345 mongodb://localhost:27017/books ~/cs544/data/2000-books.json.gz
  C-c C-c #terminate using control-C
$
