import './style.css';

import $ from 'jquery';        //make jquery() available as $
import Meta from './meta.js';  //bundle the input to this program

//default values
const DEFAULT_REF = '_';       //use this if no ref query param
const N_UNI_SELECT = 4;        //switching threshold between radio & select
const N_MULTI_SELECT = 4;      //switching threshold between checkbox & select

/*************************** Utility Routines **************************/

/** Return `ref` query parameter from window.location */
function getRef() {
  const url = new URL(window.location);
  const params = url.searchParams;
  return params && params.get('ref');
}

/** Return window.location url with `ref` query parameter set to `ref` */
function makeRefUrl(ref) {
  const url = new URL(window.location);
  url.searchParams.set('ref', ref);
  return url.toString();
}

/** Return a jquery-wrapped element for tag and attr */
function makeElement(tag, attr={}) {
  const $e = $(`<${tag}/>`);
  Object.entries(attr).forEach(([k, v]) => $e.attr(k, v));
  return $e;
}

/** Given a list path of accessors, return Meta[path].  Handle
 *  occurrences of '.' and '..' within path.
 */
function access(path) {
  const normalized = path.reduce((acc, p) => {
    if (p === '.') {
      return acc;
    }
    else if (p === '..') {
      return acc.length === 0 ? acc : acc.slice(0, -1)
    }
    else {
      return acc.concat(p);
    }
  }, []);
  return normalized.reduce((m, p) => m[p], Meta);
}

/** Return an id constructed from list path */
function makeId(path) { return ('/' + path.join('/')); }

function getType(meta) {
  return meta.type || 'block';
}

/** Return a jquery-wrapped element <tag meta.attr>items</tag>
 *  where items are the recursive rendering of meta.items.
 *  The returned element is also appended to $element.
 */
function items(tag, meta, path, $element) {
  const $e = makeElement(tag, meta.attr);
  (meta.items || []).
    forEach((item, i) => render(path.concat('items', i), $e));
  $element.append($e);
  return $e;
}

/************************** Event Handlers *****************************/

//@TODO

/********************** Type Routine Common Handling *******************/

//@TODO


/***************************** Type Routines ***************************/

//A type handling function has the signature (meta, path, $element) =>
//void.  It will append the HTML corresponding to meta (which is
//Meta[path]) to $element.

function block(meta, path, $element) { items('div', meta, path, $element); }

function form(meta, path, $element) {
  const $form = items('form', meta, path, $element);
  $form.submit(function(event) {
    event.preventDefault();
    const $form = $(this);
    const results = $( this ).serializeArray();
    let res = {};
    for (let i=0; i<results.length; i++) {
      //const results_1 = (results[i].name + ":" + results[i].value);
      var aa = $('[name='+results[i].name+']', $form);
      if($(aa).attr("multiple") || $(aa).attr("type") === "checkbox") {
        if(res[results[i].name]) {
          res[results[i].name].push(results[i].value);
        } else {
          res[results[i].name] = [results[i].value];
        }
      } else {
        res[results[i].name] = results[i].value;
      }
    }
    console.log(JSON.stringify(res, null, 2));
  });
}

function header(meta, path, $element) {
  const $e = makeElement(`h${meta.level || 1}`, meta.attr);
  $e.text(meta.text || '');
  $element.append($e);
}

function input(meta, path, $element) {
  //@TODO
  let text;
  if (meta.required === true) {
    text = meta.text+"*"
  }else{
    text = meta.text
  }
  let id;
  id = makeId(path)
  const $label = makeElement('label', {for:id}).text(text)
  $element.append($label)
  if (meta.subType === undefined) {
    Object.assign(meta.attr,{"id":id,type:"text"})
  } else {
    Object.assign(meta.attr,{"id":id,type:meta.subType})
  }
  const $div = makeElement('div', {})
  const $input = makeElement('input', meta.attr);
  // let erid = {"class":"error", "id":id+"-err"}
  // const $error = makeElement('div', erid);
  $div.append($input);
  // $div.append($error);
  if(meta.required)
  {
    //let erid = {"class":"error", "id":id+"-err"}
    let erid = {"class":"error", "id":id+"-err"}
    const reqWordMsgDiv = makeElement('div', erid);
    //$(reqWordMsgDiv).addClass("error");
    $div.append(reqWordMsgDiv);
    $input.blur(function()
    {
      reqFieldBlur(meta,this);
    });
  }
  $element.append($div)
}

function reqFieldBlur(meta, inpEle)
{
  if(!$(inpEle).val().trim()) {
    $(inpEle).next().text("The field "+ meta.text +" must be specified.");
    //$(inpEle).next().text("Field " + meta.text);
  } else
  {
    $(inpEle).next().text("");
  }
}

function link(meta, path, $element) {
  const parentType = getType(access(path.concat('..')));
  const { text='', ref=DEFAULT_REF } = meta;
  const attr = Object.assign({}, meta.attr||{}, { href: makeRefUrl(ref) });
  $element.append(makeElement('a', attr).text(text));
}

function multiSelect(meta, path, $element) {
  //@TODO
  let text;
  if (meta.required === true) {
    text = meta.text+"*"
  }else{
    text = meta.text
  }
  if (meta.items.length < (N_MULTI_SELECT || 4) ) {
    let id = makeId(path)
    const $label = makeElement('label', {for:id}).text(text)
    $element.append($label)
    const $div = makeElement('div', {})
    const $div_1 = makeElement('div', {})
    $($div_1).addClass("fieldset");
    for (let i=0; i<meta.items.length; i++) {
      let id_1 = makeId(path)+"-"+i
      Object.assign(meta.attr,{"id":id, "value":meta.items[i].key, type:"checkbox"})
      const $input = makeElement('input', meta.attr)
      const $label_1 = makeElement('label', {for:id}).text(meta.items[i].key)
      $div_1.append($label_1, $input)
      $div.append($div_1)
      $element.append($div)
    }
  }
  else if (meta.items.length > (N_UNI_SELECT || 4)) {
    let id = makeId(path)
    const $label = makeElement('label', {for:id}).text(text)
    $element.append($label)
    const $div = makeElement('div', {})
    let ty = {"multiple":"multiple"}
    const ta = Object.assign({}, meta.attr, ty)
    const $div_1 = makeElement('select', ta)
    //$($div_1).addClass("fieldset");
    for (let i=0; i<meta.items.length; i++) {
      // let va = meta.items[i].text
      // let type = {"value": meta.items[i].text}
      // const te = Object.assign({}, type)
      // const $opt = makeElement('option', te).text(meta.items[i].text);
      let $opt = opt_select_1(meta,i)
      $div_1.append($opt)
      $div.append($div_1)
      $element.append($div)
    }
  }
}

function para(meta, path, $element) { items('p', meta, path, $element); }

function segment(meta, path, $element) {
  if (meta.text !== undefined) {
    $element.append(makeElement('span', meta.attr)).text(meta.text);
  }
  else {
    items('span', meta, path, $element);
  }
}

function submit(meta, path, $element) {
  //@TODO
  const $div = makeElement('div', {})
  $element.append($div)
  let type = {"type":"submit"}
  const te = Object.assign({}, meta.attr, type)
  const $button = makeElement('button', te).text(meta.text || 'submit');
  $element.append($button)
}

function opt_select_1(meta,i) {
  let va = meta.items[i].text
  let type = {"value": meta.items[i].key}
  const te = Object.assign({}, type)
  const $opt = makeElement('option', te).text(meta.items[i].text);
  return $opt
}

function uniSelect(meta, path, $element) {
  //@TODO
  let text;
  if (meta.required === true) {
    text = meta.text+"*"
  }else{
    text = meta.text
  }
  if (meta.items.length < (N_UNI_SELECT || 4) ) {
      let id = makeId(path)
      const $label = makeElement('label', {for:id}).text(text)
      $element.append($label)
      const $div = makeElement('div', {})
      const $div_1 = makeElement('div', {});
      $($div_1).addClass("fieldset");
      for (let i=0; i<meta.items.length; i++) {
        let id_1 = makeId(path)+"-"+i
        Object.assign(meta.attr,{"id":id_1, "value":meta.items[i].key, type:"radio"})
        const $input = makeElement('input', meta.attr)
        const $label_1 = makeElement('label', {for:id}).text(meta.items[i].key)
        $div_1.append($label_1, $input)
        $div.append($div_1)
        if(meta.required)
        {
          let erid = {"class":"error", "id":id+"-err"}
          const reqWordMsgDiv = makeElement('div', erid);
          $(reqWordMsgDiv).addClass("error");
          $div.append(reqWordMsgDiv);
          $input.blur(function()
          {
            reqFieldBlur(meta, this);
          });
        }
        $element.append($div)
      }
  }
  else if (meta.items.length > (N_UNI_SELECT || 4)) {
    let id = makeId(path)
    const $label = makeElement('label', {for:id}).text(text)
    $element.append($label)
    const $div = makeElement('div', {})
    const ta = Object.assign({}, meta.attr)
    const $div_1 = makeElement('select', ta)
    for (let i=0; i<meta.items.length; i++) {
      let $opt = opt_select_1(meta,i)
      $div_1.append($opt)
      $div.append($div_1)
      if(meta.required)
      {
        let erid = {"class":"error", "id":id+"-err"}
        const reqWordMsgDiv = makeElement('div', erid);
        $(reqWordMsgDiv).addClass("error");
        $div.append(reqWordMsgDiv);
        $opt.blur(function()
        {
          reqFieldBlur(meta, this);
        });
      }
      $element.append($div)
    }
  }
}

//map from type to type handling function.
const FNS = {
  block,
  form,
  header,
  input,
  link,
  multiSelect,
  para,
  segment,
  submit,
  uniSelect,
  opt_select_1,
};

/*************************** Top-Level Code ****************************/

function render(path, $element=$('body')) {
  const meta = access(path);
  if (!meta) {
    $element.append(`<p>Path ${makeId(path)} not found</p>`);
  }
  else {
    const type = getType(meta);
    const fn = FNS[type];
    if (fn) {
      fn(meta, path, $element);
    }
    else {
      $element.append(`<p>type ${type} not supported</p>`);
    }
  }
}

function go() {
  const ref = getRef() || DEFAULT_REF;
  render([ ref ]);
}

go();
