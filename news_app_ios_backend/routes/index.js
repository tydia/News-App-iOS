/* Get main content */

var express = require('express')
var router = express.Router()
const request = require('request')
const googleTrends = require('google-trends-api')

const guardianAPIkey = 'c17ff97f-700d-4640-8846-ea2f2ea39779'

router.get('/home', function(req, res, next) {
  const url = 'http://content.guardianapis.com/search?orderby=newest&show-fields=starRating,headline,thumbnail,short-url&api-key='
               +guardianAPIkey

  // console.log(url)
  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    let articles = []
    let numArticles
    rawDataJSON.pageSize > 10 ? numArticles=10 : numArticles=rawDataJSON.pageSize
    for (let i = 0; i < numArticles; i++) {
      let currObj = {"title" : rawDataJSON.results[i].webTitle,
                      "image" : rawDataJSON.results[i].fields.thumbnail,
                      'section' : rawDataJSON.results[i].sectionName,
                      'time' : (rawDataJSON.results[i].webPublicationDate),
                      'articleID' : rawDataJSON.results[i].id
                    }
      articles.push(currObj);
    }

    res.json(articles)
  })
})

router.get('/world', function(req, res, next) {
  const url = 'https://content.guardianapis.com/world?api-key='+guardianAPIkey
  + '&show-blocks=all'

  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    let articles = []
    let numArticles
    rawDataJSON.pageSize > 10 ? numArticles=10 : numArticles=rawDataJSON.pageSize
    for (let i = 0; i < numArticles; i++) {
      // console.log(rawDataJSON.results[i].id)
      let imageUrl = ""
      if (typeof rawDataJSON.results[i].blocks.main !== 'undefined') {
        if (typeof rawDataJSON.results[i].blocks.main.elements[0].assets.pop() !== 'undefined') {
          imageUrl = rawDataJSON.results[i].blocks.main.elements[0].assets.pop().file
        }
      }
      let currObj = { 'title' : rawDataJSON.results[i].webTitle,
                      'image' : imageUrl,
                      'section' : rawDataJSON.results[i].sectionName,
                      'time' : (rawDataJSON.results[i].webPublicationDate),
                      'articleID' : rawDataJSON.results[i].id
                    }
      articles.push(currObj);
    }

    res.json(articles)
  })
})

router.get('/business', function(req, res, next) {
  const url = 'https://content.guardianapis.com/business?api-key='+guardianAPIkey
  + '&show-blocks=all'

  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    let articles = []
    let numArticles
    rawDataJSON.pageSize > 10 ? numArticles=10 : numArticles=rawDataJSON.pageSize
    for (let i = 0; i < numArticles; i++) {
      // console.log(rawDataJSON.results[i].articleID)
      let imageUrl = ""
      if (typeof rawDataJSON.results[i].blocks.main !== 'undefined') {
        if (typeof rawDataJSON.results[i].blocks.main.elements[0].assets.pop() !== 'undefined') {
          imageUrl = rawDataJSON.results[i].blocks.main.elements[0].assets.pop().file
        }
      }
      let currObj = { 'title' : rawDataJSON.results[i].webTitle,
                      'image' : imageUrl,
                      'section' : rawDataJSON.results[i].sectionName,
                      'time' : (rawDataJSON.results[i].webPublicationDate),
                      'articleID' : rawDataJSON.results[i].id
                    }
      articles.push(currObj);
    }

    res.json(articles)
  })
})

router.get('/politics', function(req, res, next) {
  const url = 'https://content.guardianapis.com/politics?api-key='+guardianAPIkey
  + '&show-blocks=all'

  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    let articles = []
    let numArticles
    rawDataJSON.pageSize > 10 ? numArticles=10 : numArticles=rawDataJSON.pageSize
    for (let i = 0; i < numArticles; i++) {
      // console.log(rawDataJSON.results[i].articleID)
      let imageUrl = ""
      if (typeof rawDataJSON.results[i].blocks.main !== 'undefined') {
        if (typeof rawDataJSON.results[i].blocks.main.elements[0].assets.pop() !== 'undefined') {
          imageUrl = rawDataJSON.results[i].blocks.main.elements[0].assets.pop().file
        }
      }
      let currObj = { 'title' : rawDataJSON.results[i].webTitle,
                      'image' : imageUrl,
                      'section' : rawDataJSON.results[i].sectionName,
                      'time' : (rawDataJSON.results[i].webPublicationDate),
                      'articleID' : rawDataJSON.results[i].id
                    }
      articles.push(currObj);
    }

    res.json(articles)
  })
})

router.get('/sport', function(req, res, next) {
  const url = 'https://content.guardianapis.com/sport?api-key='+guardianAPIkey
  + '&show-blocks=all'

  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    let articles = []
    let numArticles
    rawDataJSON.pageSize > 10 ? numArticles=10 : numArticles=rawDataJSON.pageSize
    for (let i = 0; i < numArticles; i++) {
      // console.log(rawDataJSON.results[i].articleID)
      let imageUrl = ""
      if (typeof rawDataJSON.results[i].blocks.main !== 'undefined') {
        if (typeof rawDataJSON.results[i].blocks.main.elements[0].assets.pop() !== 'undefined') {
          imageUrl = rawDataJSON.results[i].blocks.main.elements[0].assets.pop().file
        }
      }
      let currObj = { 'title' : rawDataJSON.results[i].webTitle,
                      'image' : imageUrl,
                      'section' : rawDataJSON.results[i].sectionName,
                      'time' : (rawDataJSON.results[i].webPublicationDate),
                      'articleID' : rawDataJSON.results[i].id
                    }
      articles.push(currObj);
    }

    res.json(articles)
  })
})

router.get('/technology', function(req, res, next) {
  const url = 'https://content.guardianapis.com/technology?api-key='+guardianAPIkey
  + '&show-blocks=all'

  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    let articles = []
    let numArticles
    rawDataJSON.pageSize > 10 ? numArticles=10 : numArticles=rawDataJSON.pageSize
    for (let i = 0; i < numArticles; i++) {
      // console.log(rawDataJSON.results[i].id)
      let imageUrl = ""
      if (typeof rawDataJSON.results[i].blocks.main !== 'undefined') {
        if (typeof rawDataJSON.results[i].blocks.main.elements[0].assets.pop() !== 'undefined') {
          imageUrl = rawDataJSON.results[i].blocks.main.elements[0].assets.pop().file
        }
      }
      let currObj = { 'title' : rawDataJSON.results[i].webTitle,
                      'image' : imageUrl,
                      'section' : rawDataJSON.results[i].sectionName,
                      'time' : (rawDataJSON.results[i].webPublicationDate),
                      'articleID' : rawDataJSON.results[i].id
                    }
      articles.push(currObj);
    }

    res.json(articles)
  })
})

router.get('/science', function(req, res, next) {
  const url = 'https://content.guardianapis.com/science?api-key='+guardianAPIkey
  + '&show-blocks=all'

  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    let articles = []
    let numArticles
    rawDataJSON.pageSize > 10 ? numArticles=10 : numArticles=rawDataJSON.pageSize
    for (let i = 0; i < numArticles; i++) {
      // console.log(rawDataJSON.results[i].id)
      let imageUrl = ""
      if (typeof rawDataJSON.results[i].blocks.main !== 'undefined') {
        if (typeof rawDataJSON.results[i].blocks.main.elements[0].assets.pop() !== 'undefined') {
          imageUrl = rawDataJSON.results[i].blocks.main.elements[0].assets.pop().file
        }
      }
      let currObj = { 'title' : rawDataJSON.results[i].webTitle,
                      'image' : imageUrl,
                      'section' : rawDataJSON.results[i].sectionName,
                      'time' : (rawDataJSON.results[i].webPublicationDate),
                      'articleID' : rawDataJSON.results[i].id
                    }
      articles.push(currObj);
    }

    res.json(articles)
  })
})

router.get('/trending', function(req, res, next) {
  qs = req.query.q

  googleTrends.interestOverTime({keyword: qs, startTime: new Date('2019-06-01')})
  .then(function(results){
    let response = JSON.parse(results)
    let valuesArray = response.default.timelineData
    if (typeof valuesArray !== 'undefined') {
      let rstArray = []
      for (let i=0; i<valuesArray.length; i++) {
        rstArray.push(valuesArray[i].value[0])
      }
      res.json(rstArray)
    } else {
      res.json({"err":"no results"})
    }
  
  })
  .catch(function(err){
    // console.error('Oh no there was an error', err);
    res.json({"err":err})
  })
})


module.exports = router;
