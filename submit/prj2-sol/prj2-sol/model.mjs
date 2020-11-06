import META from './meta.mjs';
import Validator from './validator.mjs';
import ModelError from './model-error.mjs';

import mongo from 'mongodb';

import assert from 'assert';
import util from 'util';


/** 

All detected errors should be reported by throwing an array of
ModelError objects.  

Errors are of two types:

  + *Local errors* depend only on the field values of the current data
    item.  Local errors are specified and checked using meta.mjs
    and validator.mjs and are not specified below.

  + *Global errors* depend on data items other than the current data
    item.  The comments for the code below document global errors.

Each ModelError must be specified with an error code (defined below)
and an error message which should be as specific as possible.  If the
error is associated with a particular field, then the internal name of
that field should be filled in to the ModelError object.  Note that if
an error message refers to the name of the field, it should do so
using the external name (`label`) of the field.

The codes for the ModelError include the following:

BAD_ACT:
  Action does not correspond to one of the model action routines.

BAD_FIELD:
  An object contains an unknown field name or a forbidden field.

BAD_FIELD_VALUE:
  The value of a field does not meet its specs.

BAD_ID:
  Object not found for specified ID.  Includes an error when some field 
  specifies an id for some other object, but there is no object having
  that ID.

DB:
  Database error

FORM_ERROR:
  Form is invalid.

MISSING_FIELD:
  The value of a required field is not specified.

*/

export default class Model {

  /** Set up properties from props as properties of this. */
  constructor(props) {
    Object.assign(this, props);
  }

  /** Return a new instance of Model set up to use database specified
   *  by dbUrl
   */ 
  static async make(dbUrl) {
    let client, dataBaseName;
    try {
      //@TODO
      client = await mongo.connect(dbUrl, MONGO_CONNECT_OPTIONS);
      const db = client.db(dataBaseName);
      const bookCollection = db.collection(BOOKS);
      const index = { title: 'text', authors: 'text'}; 
      await bookCollection.createIndex(index);
      const cartCollection = db.collection(CARTS);

      const props = {
	    validator: new Validator(META),
      //@TODO other properties
      client: client, db: db, bookCollection, cartCollection,
      };
      const model = new Model(props);
      return model;
    }
    catch (err) {
      const msg = `cannot connect to URL "${dbUrl}": ${err}`;
      throw [ new ModelError('DB', msg) ];
    }
  }

  /** Release all resources held by this model.  Specifically,
   *  close any database connections.
   */
  async close() {
    //@TODO
    await this.client.close();
  }

  /** Clear out all data stored within this model. */
  async clear() {
    //@TODO
    try {
      await this.bookCollection.dropDatabase();
      await this.cartCollection.dropDatabase();
    }
    catch (err) {
      throw [ new ModelError('DB', err.message || err.toString()) ];
    }
  }
  
  //Action routines
  /** Create a new cart.  Returns ID of newly created cart.  The
   * returned ID should not be generated by the database; it should
   * also not be easily guessable.
   *
   *  The new cart should have a `_lastModified` field set to the
   *  current Date timestamp.
   */
  async newCart(rawNameValues) {
    const nameValues = this._validate('newCart', rawNameValues);
    //@TODO
    try {
      const id = (Math.random()).toString();
      const cart = {_id: id, _lastModified: new Date()};
      //const cartCollection = db.collection(CARTS);
      const ret = await this.cartCollection.insertOne(cart);
      if (ret.insertedCount <= 0) throw [new ModelError('DB', err.message)];
      return id;
    }
    catch(err) {
      throw [ new ModelError('DB', err.message || err.toString()) ];
    }
  }

  /** Given fields { cartId, sku, nUnits } = rawNameValues, update
   *  number of units for sku to nUnits.  Update `_lastModified` field
   *  of cart to current Date timestamp.
   *
   *  Global Errors:
   *    BAD_ID: cartId does not reference a cart.
   *            sku does not specify the isbn of an existing book.
   */

   async cartItem(rawNameValues) {
    const nameValues = this._validate('cartItem', rawNameValues);

    const get_book_data = await this.db.collection("book_data").find({"isbn":nameValues.sku}).toArray()
    if(get_book_data.length === 0){
      throw [new ModelError("BAD_ID","unknow sku "+nameValues.sku,"sku")]
    }
    let set_parameters = {};
    set_parameters[nameValues.sku] = nameValues.nUnits;
    let update;
    let cart_item;
    if( nameValues.nUnits === 0){
      cart_item = {$currentDate:{_lastModified:true},$unset:{[nameValues.sku]:1}} 
    }else{
      cart_item = {$currentDate:{_lastModified:true},  $set:set_parameters}
    }
    const response = await this.db.collection("cart").updateOne({"_id":nameValues.cartId},cart_item)
    if(response.modifiedCount === 0){
      throw [new ModelError("BAD_ID","no updates for cart "+nameValues.cartId,"cartId")]
    }
  }
   
   
  /** Given fields { cartId } = nameValues, return cart identified by
   *  cartId.  The cart is returned as an object which contains a
   *  mapping from SKU's to *positive* integers (representing the
   *  number of units of the item identified by the SKU contained in
   *  the cart).  Addtionally, it must also have a `_lastModified`
   *  property containing a Date timestamp specifying the last time the
   *  cart was modified.
   *
   *  Globals Errors:
   *    BAD_ID: cartId does not reference a cart.
   */
  async getCart(rawNameValues) {
    const nameValues = this._validate('getCart', rawNameValues);
    //@TODO
    try {
      const ret = await this.cartCollection.findOne({_id: nameValues.cartId}, { projection: { _id: 0 } });

      if (ret === null) {
        throw [new ModelError('BAD_ID', `not able to find cart ${nameValues.cartId}`, 'cartId')]
      }
      return ret;
    }
    catch (err) {
      throw [ new ModelError('DB', err.message || err.toString()) ];
    }
  }

  /** Given fields { isbn, title, authors, publisher, year, pages } =
   *  nameValues for a book, add the book to this model.  The isbn
   *  field should uniquely identify the book.  Note that if the book
   *  already exists in this model, then this routine should merely
   *  update the information associated with the book.
   *
   *  Returns the isbn of the added/updated book.
   *
   *  This routine should set a `_lastModified` field in the book to
   *  the current Date timestamp.
   */
  async addBook(rawNameValues) {
    const nameValues = this._validate('addBook', rawNameValues);
    //@TODO
    //const bookCollection = await this.db.collection(BOOK_COLLECTION).find({isbn: nameValues.isbn}).toArray();
    try {
      //line for id
      const bookDetail = Object.assign({}, nameValues, { _id, _lastModified: new Date()});
      const booksCollection = this.db.collection(BOOK);
      const res = await booksCollection.updateOne( nameValues, { $set: bookDetails }, { upsert: true });
      return _id;
    }
    catch (err) {
      throw [ new ModelError('DB', err.message || err.toString()) ];
    }
  }

  /** Given fields { isbn, authorsTitle, _count=COUNT, _index=0 } =
   *  nameValues, retrieve list of all books with specified isbn (if
   *  any) and the words specified in authorsTitle occurring in either
   *  the book's authors field or the title field.  The retrieved
   *  results are sorted in ascending order by title.  The returned
   *  results have up to _count books starting at index _index in the
   *  retrieved results.  The `_index` and `_count` fields allow
   *  paging through the search results.
   *
   *  Will return [] if no books match the search criteria.
   */
  async findBooks(rawNameValues) {

    const nameValues = this._validate('findBooks', rawNameValues);
    //@TODO
    const searchData = {}
    if(rawNameValues.hasOwnProperty("isbn")){
      searchData["isbn"] = rawNameValues.isbn
	  
    }else{
      const find_data = { $search : nameValues.authorsTitleSearch}
      searchData.$text = find_data
    }

    await this.db.collection(BOOKS).createIndex({title:"text",authors:"text"})
    const data =  await this.db.collection(BOOKS).find(searchData)
        .limit(nameValues._count||COUNT)
        .sort({"title":1})
        .skip(nameValues._index|| 0)
        .project({_id:0})
        .toArray()

    return data;
  }

  //wrapper around this.validator to verify that no external field
  //is _id which is used by mongo
  _validate(action, rawNameValues) {
    let errs = [];
    let nameValues;
    try {
      nameValues = this.validator.validate(action, rawNameValues);
    }
    catch (err) {
      if (err instanceof Array) { //something we understand
	errs = err;
      }
      else {
	throw err; //not expected, throw upstairs
      }
    }
    if (rawNameValues._id !== undefined) {
      errs.push(new ModelError('BAD_FIELD', '_id field not permitted', '_id'));
    }
    if (errs.length > 0) throw errs;
    return nameValues;
  }
  
  
};

//use as second argument to mongo.connect()
const MONGO_CONNECT_OPTIONS = { useUnifiedTopology: true };

//default value for _count in findBooks()
const COUNT = 5;

//define private constants and functions here.

const BOOKS = 'books';
const CARTS = 'carts';
