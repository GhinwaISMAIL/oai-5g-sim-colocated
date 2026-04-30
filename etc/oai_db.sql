SET SESSION sql_mode = '';
CREATE DATABASE IF NOT EXISTS oai_db;
USE oai_db;

CREATE TABLE IF NOT EXISTS users (
  userid varchar(255) NOT NULL,
  imsi varchar(15) NOT NULL,
  msisdn varchar(25),
  imei varchar(15),
  access_restriction_data int(10) unsigned,
  mme_identity_fqdn varchar(255),
  ue_ambr_ul varchar(11),
  ue_ambr_dl varchar(11),
  access_mode varchar(2) NOT NULL DEFAULT 'IT',
  mcc varchar(3),
  mnc varchar(3),
  ue_ip varchar(15),
  ms_ps_status varchar(10) DEFAULT 'PURGED',
  rau_tau_timer int(10) unsigned DEFAULT '120',
  ue_status int(10) unsigned DEFAULT '0',
  PRIMARY KEY (userid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS mmeidentity (
  idmmeidentity int(11) NOT NULL AUTO_INCREMENT,
  mmehost varchar(255),
  mmerealm varchar(100),
  ue_reachability tinyint(1) NOT NULL,
  PRIMARY KEY (idmmeidentity)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS pdn (
  id int(11) NOT NULL AUTO_INCREMENT,
  apn varchar(60) NOT NULL,
  pdn_type int(11) NOT NULL,
  pdn_ipv4 varchar(15),
  pdn_ipv6 varchar(49),
  aggregate_ambr_ul int(10) unsigned,
  aggregate_ambr_dl int(10) unsigned,
  pgw_id int(11) NOT NULL,
  users_imsi varchar(15) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS pgw (
  idpgw int(11) NOT NULL AUTO_INCREMENT,
  ipv4 varchar(15) NOT NULL,
  ipv6 varchar(49),
  PRIMARY KEY (idpgw)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS AuthenticationSubscription (
  ueid VARCHAR(15) NOT NULL,
  authenticationMethod VARCHAR(25) NOT NULL,
  encPermanentKey VARCHAR(32),
  protectionParameterId VARCHAR(32),
  sequenceNumber JSON,
  authenticationManagementField VARCHAR(4),
  algorithmId VARCHAR(25),
  encOpcKey VARCHAR(32),
  encTopcKey VARCHAR(32),
  vectorGenerationInHss TINYINT(1),
  n5gcAuthMethod VARCHAR(25),
  rgAuthenticationInd TINYINT(1),
  supi VARCHAR(15),
  PRIMARY KEY (ueid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS SessionManagementSubscriptionData (
  ueid VARCHAR(15) NOT NULL,
  servingPlmnid VARCHAR(15) NOT NULL,
  singleNssai JSON NOT NULL,
  dnnConfigurations JSON,
  PRIMARY KEY (ueid, servingPlmnid, singleNssai(100))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS AccessAndMobilitySubscriptionData (
  ueid VARCHAR(15) NOT NULL,
  servingPlmnid VARCHAR(15) NOT NULL,
  supportedFeatures VARCHAR(25),
  gpsis JSON,
  internalGroupIds JSON,
  sharedVnGroupDataIds JSON,
  subscribedUeAmbr JSON,
  nssai JSON,
  ratRestrictions JSON,
  forbiddenAreas JSON,
  serviceAreaRestriction JSON,
  coreNetworkTypeRestrictions JSON,
  rfspIndex INT(10) UNSIGNED,
  subsRegTimer INT(10) UNSIGNED,
  ueUsageType INT(10) UNSIGNED,
  mpsPriority TINYINT(1),
  mcsPriority TINYINT(1),
  activeTime INT(10) UNSIGNED,
  sorInfo JSON,
  sorInfoExpectInd TINYINT(1),
  sorafRetrieval TINYINT(1),
  sorUpdateIndicatorList JSON,
  upuInfo JSON,
  micoAllowed TINYINT(1),
  sharedAmDataIds JSON,
  odbPacketServices JSON,
  serviceGapTime INT(10) UNSIGNED,
  mdtUserConsent VARCHAR(25),
  mdtConfiguration JSON,
  traceData JSON,
  cagData JSON,
  stnSr VARCHAR(25),
  cMsisdn VARCHAR(25),
  nb_iot_allowed TINYINT(1),
  PRIMARY KEY (ueid, servingPlmnid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS SmfSelectionSubscriptionData (
  ueid VARCHAR(15) NOT NULL,
  servingPlmnid VARCHAR(15) NOT NULL,
  supportedFeatures VARCHAR(25),
  subscribedSnssaiInfos JSON,
  sharedSnssaiInfosId VARCHAR(25),
  PRIMARY KEY (ueid, servingPlmnid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Insert 10 UE subscribers matching CI repo credentials
-- IMSI: 208990100001100 to 208990100001109
-- Key: fec86ba6eb707ed08905757b1bb44b8f
-- OPC: C42449363BBAD02B66D16BC975D77CC1

INSERT INTO `users` VALUES
('1','208990100001100',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('2','208990100001101',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('3','208990100001102',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('4','208990100001103',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('5','208990100001104',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('6','208990100001105',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('7','208990100001106',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('8','208990100001107',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('9','208990100001108',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0),
('10','208990100001109',NULL,NULL,NULL,NULL,'200000000','100000000','IT','208','99',NULL,'PURGED',120,0);

INSERT INTO `AuthenticationSubscription` VALUES
('208990100001100','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001101','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001102','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001103','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001104','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001105','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001106','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001107','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001108','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL),
('208990100001109','5G_AKA','fec86ba6eb707ed08905757b1bb44b8f','fec86ba6eb707ed08905757b1bb44b8f','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'C42449363BBAD02B66D16BC975D77CC1',NULL,NULL,NULL,NULL);