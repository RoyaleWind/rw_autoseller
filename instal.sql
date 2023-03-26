
CREATE TABLE IF NOT EXISTS `rw_autoseller` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `items` longtext DEFAULT '[{"name":"phone","price":10,"count":0}]',
  `x` double DEFAULT 0,
  `y` double DEFAULT 0,
  `z` double DEFAULT 0,
  `r` double DEFAULT 0,
  `owner` varchar(50) DEFAULT NULL,
  `cashery` int(11) DEFAULT 0,
  `model` varchar(50) DEFAULT 'prop_vend_soda_01',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4;

