import assert from 'assert';
//import cors from 'cors';
import express from 'express';
import bodyParser from 'body-parser';
import querystring from 'querystring';

import ModelError from './model-error.mjs';

//not all codes necessary
const OK = 200;
const CREATED = 201;
const NO_CONTENT = 204;
const BAD_REQUEST = 400;
const NOT_FOUND = 404;
const CONFLICT = 409;
const SERVER_ERROR = 500;

const BASE = 'api';

export default function serve(port, meta, model) {
  const app = express();
  app.locals.port = port;
  app.locals.meta = meta;
  app.locals.model = model;
  setupRoutes(app);
  app.listen(port, function() {
    console.log(`listening on port ${port}`);
  });
}

function setupRoutes(app) {
  //app.use(cors());

  //pseudo-handlers used to set up defaults for req
  app.use(bodyParser.json());      //always parse request bodies as JSON
  app.use(reqSelfUrl, reqBaseUrl); //set useful properties in req

  //application routes
  app.get(`/${BASE}`, doBase(app));
  //@TODO: add other application routes
  app.post(`/${BASE}/${CARTS}`, doCreate(app));
  app.patch(`/${BASE}/${CARTS}/:id`, doUpdate(app));
  app.get(`/${BASE}/${BOOKS}/:isbn`, doGet(app));
  app.get(`/${BASE}/${CARTS}/:id`, doGetCart(app));
  app.get(`/${BASE}/${BOOKS}`, doGetBooks(app));

  //must be last
  app.use(do404(app));
  app.use(doErrors(app));
}

/****************************** Handlers *******************************/

/** Sets selfUrl property on req to complete URL of req,
 *  including query parameters.
 */
function reqSelfUrl(req, res, next) {
  const port = req.app.locals.port;
  req.selfUrl = `${req.protocol}://${req.hostname}:${port}${req.originalUrl}`;
  next();  //absolutely essential
}

/** Sets baseUrl property on req to complete URL of BASE. */
function reqBaseUrl(req, res, next) {
  const port = req.app.locals.port;
  req.baseUrl = `${req.protocol}://${req.hostname}:${port}/${BASE}`;
  next(); //absolutely essential
}

function doBase(app) {
  return function(req, res) { 
    try {
      const links = [
        { rel: 'self', name: 'self', href: req.selfUrl, },
        //@TODO add links for book and cart collections
        { rel: 'collection', name: 'books', href: `${req.selfUrl}/${BOOKS}` },
        { rel: 'collection', name: 'carts', href: `${req.selfUrl}/${CARTS}` },
      ];
      res.json({ links });
    }
    catch (err) {
      const mapped = mapError(err);
      res.status(mapped.status).json(mapped);
    }
  };
}

//@TODO: Add handlers for other application routes
function doCreate(app){
  return async function(req, res) {
    try {
      const result = await app.locals.model.newCart({});
      res.append('Location', requestUrl(req) + '/'+ ${result});
      res.sendStatus(CREATED);
      res.end();
    }
    catch (err) {
      const mapped = mapError(err);
      res.status(mapped.status).json(mapped);
    }
  };
}

function doUpdate(app) {
  return async function(req, res) {
    try {
      const patch = Object.assign({}, req.body);
      patch.cartId = req.params.id;
      const results = await app.locals.model.cartItem(patch);
      res.sendStatus(OK);
      res.end();
    }
    catch(err) {
      const mapped = mapError(err);
      res.status(mapped.status).json(mapped);
    }
  };
}

function doGet(app) {
  return async function(req, res) {
    try {
      const isbn = req.params.id;
      const books = await app.locals.model.findBooks({ isbn: isbn });
      if (books.length === 0) {
        res.json({
          "errors": [
            {
              "code" : "BAD_ID",
              "message" : "no book for isbn "+isbn,
              "name" : "isbn"
            }
          ],
          "status" : 404
        });
      }
    }
    catch(err) {
      const mapped = mapError(err);
      res.status(mapped.status).json(mapped);
    }
  };
}

function doGetCart(app) {
  return async function(req, res) {
    try {
      const response = {_lastModified:"",links: [{ href: req.selfUrl, rel: 'self', name: 'self'}],};
      const id = req.params.id;
      const cart = await app.locals.model.getCart({ cartId: id });
      if (cart.length === 0) {
        res.json( {
          "errors" : [
            {
              "code" : "BAD_ID",
              "message" : "cart id not found "+id,
              "name" : "cartId"
            }
          ],
          "status" : 404
        });
      }
      else {
        response._lastModified = cart._lastModified
        delete cart._lastModified
        const items = []
        for (var key of Object.keys(cart)) {
            let temp = { }
            temp["links"] = [ { rel: 'item', name: 'book', href: req.baseUrl+"/books/"+key} ]
            temp["sku"] = key;
            temp["nUnits"] = cart[key]
            items.push(temp)
        }
        response.cart = items
        res.json(response)
      }
    }
    catch(err) {
      const mapped = mapError(err);
      res.status(mapped.status).json(mapped);
    }
  };
}

function doGetBooks(app) {
  return async function(req, res){
    const parameters = req.query || {};
    try {
      const startIndex = Number(parameters._index || 0);
      const count = Number(parameters._count || 5);
      const params = Object.assign({}, parameters, {_count: (+parameters._count || 5)+1});

      if(!parameters){
        res.json(
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
        )
      }

      const temp = await app.locals.model.findBooks(params);
      const results = temp.slice(0, params._count - 1);

      results.forEach(element => element["links"] = [{
        "href" : req.baseUrl + `/${BOOKS}/${item.isbn}`,
        "name" : "book",
        "rel" : "details"
      }]);
      const data = {
        links : [{ rel: 'self', name: 'self', href: req.selfUrl }],
        result: results
      };

      const next_Index = Index + count;
      if (temp.length === params._count) {
        const next_Parameter = Object.assign({}, parameters, {_index: next_Index });
        const next_Url = `${req.baseUrl}/${BOOKS}?${querystring.stringify(next_Parameter)}`;
        data.links.push({rel: 'next', href: next_Url, name: 'next'});
      }

      if (Index > 0) {
        let previous_Index = Index - count;
        if (previous_Index < 0) previous_Index = 0;
        const previous_Parameter = Object.assign({}, parameters, { _index: previous_Index });
        const previous_Url = `${req.baseUrl}/${BOOKS}?${querystring.stringify(previous_Parameter)}`;
        data.links.push({ rel: 'prev', href: previous_Url, name: 'prev' });
      }

      res.json(data);
    }
    catch (err) {
      const mapped = mapError(err);
      res.status(mapped.status).json(mapped);
    }
  }
}

/** Default handler for when there is no route for a particular method
 *  and path.
 */
function do404(app) {
  return async function(req, res) {
    const message = `${req.method} not supported for ${req.originalUrl}`;
    const result = {
      status: NOT_FOUND,
      errors: [	{ code: 'NOT_FOUND', message, }, ],
    };
    res.type('text').
	status(404).
	json(result);
  };
}


/** Ensures a server error results in nice JSON sent back to client
 *  with details logged on console.
 */ 
function doErrors(app) {
  return async function(err, req, res, next) {
    const result = {
      status: SERVER_ERROR,
      errors: [ { code: 'SERVER_ERROR', message: err.message } ],
    };
    res.status(SERVER_ERROR).json(result);
    console.error(err);
  };
}


/*************************** Mapping Errors ****************************/

const ERROR_MAP = {
  BAD_ID: NOT_FOUND,
}

/** Map domain/internal errors into suitable HTTP errors.  Return'd
 *  object will have a "status" property corresponding to HTTP status
 *  code and an errors property containing list of error objects
 *  with code, message and name properties.
 */
function mapError(err) {
  const isDomainError =
    (err instanceof Array && err.length > 0 && err[0] instanceof ModelError);
  const status =
    isDomainError ? (ERROR_MAP[err[0].code] || BAD_REQUEST) : SERVER_ERROR;
  const errors =
	isDomainError
	? err.map(e => ({ code: e.code, message: e.message, name: e.name }))
        : [ { code: 'SERVER_ERROR', message: err.toString(), } ];
  if (!isDomainError) console.error(err);
  return { status, errors };
} 

/****************************** Utilities ******************************/

function requestUrl(req) {
  const port = req.app.locals.port;
  const originalUrl = req.originalUrl.replace(/\/?(\?.*)?$/, '');
  return `${req.protocol}://${req.hostname}:${port}${req.originalUrl}`;
}

