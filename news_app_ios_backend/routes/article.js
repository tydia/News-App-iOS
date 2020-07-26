const express = require('express')
const router = express.Router();
const request = require('request')

const guardianAPIkey = 'c17ff97f-700d-4640-8846-ea2f2ea39779'

router.get('/getArticle', function(req, res, next) {
  articleID = req.query.id
  
  const url = 'https://content.guardianapis.com/'+articleID
                + "?api-key="+guardianAPIkey+'&show-blocks=all'
  // console.log(url)
  request.get(url, (err, response, body) => {
    rawDataJSON = JSON.parse(body).response

    if(err || rawDataJSON.status !== 'ok') {
      console.log(err)
      return next(err)
    }

    let bodyHtml = ""
    let numBodyHtml = (rawDataJSON.content.blocks.body).length
    for (let i = 0; i < numBodyHtml; i++) {
      bodyHtml += rawDataJSON.content.blocks.body[i].bodyHtml
      // bodyHtml += "<br><br>"
    }
    // console.log(rawDataJSON.content.sectionId)
    let imageUrl = ""
    if (typeof rawDataJSON.content.blocks.main !== 'undefined') {
      if (typeof rawDataJSON.content.blocks.main.elements[0].assets.pop() !== 'undefined') {
        imageUrl = rawDataJSON.content.blocks.main.elements[0].assets.pop().file
      }
    }
    let currObj = { "image" : imageUrl,
                    "title" : rawDataJSON.content.webTitle,
                    'date' : (rawDataJSON.content.webPublicationDate),
                    'section' : rawDataJSON.content.sectionName,
                    'description' : bodyHtml,
                    'url' : rawDataJSON.content.webUrl
                  }

    res.json(currObj)
  })
})

module.exports = router;
