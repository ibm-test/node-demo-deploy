var express = require('express');
var router = express.Router();
var company = require('../demo.json');

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { company: company });
});

module.exports = router;
