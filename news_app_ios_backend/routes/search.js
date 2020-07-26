const express = require('express')
const router = express.Router();
const request = require('request')

const guardianAPIkey = 'c17ff97f-700d-4640-8846-ea2f2ea39779'

router.get('/searchArticles', function(req, res, next) {
  qs = req.query.q
  // console.log("query: ", req.query.q)

  let resultArticles = []
  let currObj

  const guardianURL = 'https://content.guardianapis.com/search?q='+qs
                + "&api-key="+guardianAPIkey+'&show-blocks=all'
  request.get(guardianURL, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    // console.log(rawDataJSON)

    if(err || rawDataJSON.status !== 'ok' || !rawDataJSON) {
      console.log(err)
      return next(err)
    }

    // check no search result
    if (rawDataJSON.results.length === 0) {
      res.json({err:"no result"})
    }
    else {
      let num = rawDataJSON.results.length > 10 ? 10 : rawDataJSON.results.length
      for (let i=0; i<num; i++) {
        let imageUrl = ""
        if (typeof rawDataJSON.results[i].blocks.main !== 'undefined') {
          if (typeof rawDataJSON.results[i].blocks.main.elements[0].assets.pop() !== 'undefined') {
            imageUrl = rawDataJSON.results[i].blocks.main.elements[0].assets.pop().file
          }
        }
        currObj = { 'title' : rawDataJSON.results[i].webTitle,
                    'image' : imageUrl,
                    'time' : (rawDataJSON.results[i].webPublicationDate),
                    'articleID' : rawDataJSON.results[i].id,
                    'section' : rawDataJSON.results[i].sectionName
                  }
        resultArticles.push(currObj)
      }
      res.json(resultArticles)
    }
  })
})

module.exports = router;
