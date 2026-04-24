-- =============================================================================
-- oai_db.sql — OAI 5G Core Network Database Schema
--
-- This file is loaded automatically by MySQL on first container start
-- via the docker-entrypoint-initdb.d mechanism.
--
-- It creates all tables needed by:
--   - UDR  (subscriber data)
--   - UDM  (authentication)
--   - AMF  (mobility)
--   - SMF  (session management)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS oai_db;
USE oai_db;

-- ------------------------------------------------------------------ --
-- Authentication Subscription
-- Stores IMSI, authentication method, keys
-- ------------------------------------------------------------------ --
CREATE TABLE IF NOT EXISTS `AuthenticationSubscription` (
  `ueid`                       varchar(15) NOT NULL,
  `authenticationMethod`       varchar(20) NOT NULL,
  `encPermanentKey`            varchar(32)  DEFAULT NULL,
  `protectionParameterId`      varchar(32)  DEFAULT NULL,
  `sequenceNumber`             json         DEFAULT NULL,
  `authenticationManagementField` varchar(4) DEFAULT NULL,
  `algorithmId`                varchar(20)  DEFAULT NULL,
  `encOpcKey`                  varchar(32)  DEFAULT NULL,
  `encTopcKey`                 varchar(32)  DEFAULT NULL,
  `vectorGenerationInHss`      tinyint(1)   DEFAULT NULL,
  `n5gcAuthMethod`             varchar(15)  DEFAULT NULL,
  `rgAuthenticationInd`        tinyint(1)   DEFAULT NULL,
  PRIMARY KEY (`ueid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------------------------------------------------------ --
-- Access and Mobility Subscription Data
-- ------------------------------------------------------------------ --
CREATE TABLE IF NOT EXISTS `AccessAndMobilitySubscriptionData` (
  `ueid`                       varchar(15)  NOT NULL,
  `servingPlmnid`              varchar(15)  NOT NULL,
  `supportedFeatures`          varchar(50)  DEFAULT NULL,
  `gpsis`                      json         DEFAULT NULL,
  `internalGroupIds`           json         DEFAULT NULL,
  `sharedVnGroupDataIds`       json         DEFAULT NULL,
  `subscribedUeAmbr`           json         DEFAULT NULL,
  `nssai`                      json         DEFAULT NULL,
  `ratRestrictions`            json         DEFAULT NULL,
  `forbiddenAreas`             json         DEFAULT NULL,
  `serviceAreaRestriction`     json         DEFAULT NULL,
  `coreNetworkTypeRestrictions` json        DEFAULT NULL,
  `rfspIndex`                  int(11)      DEFAULT NULL,
  `subsRegTimer`               int(11)      DEFAULT NULL,
  `ueUsageType`                int(11)      DEFAULT NULL,
  `mpsPriority`                tinyint(1)   DEFAULT NULL,
  `mcsPriority`                tinyint(1)   DEFAULT NULL,
  `activeTime`                 int(11)      DEFAULT NULL,
  `sorInfo`                    json         DEFAULT NULL,
  `sorInfoExpectInd`           tinyint(1)   DEFAULT NULL,
  `sorafRetrieval`             tinyint(1)   DEFAULT NULL,
  `sorUpdateIndicatorList`     json         DEFAULT NULL,
  `upuInfo`                    json         DEFAULT NULL,
  `micoAllowed`                tinyint(1)   DEFAULT NULL,
  `sharedAmDataIds`            json         DEFAULT NULL,
  `odbPacketServices`          json         DEFAULT NULL,
  `subscribedinternalGroupIds` json         DEFAULT NULL,
  `pduSessionTypes`            json         DEFAULT NULL,
  `iabOperationAllowed`        tinyint(1)   DEFAULT NULL,
  PRIMARY KEY (`ueid`, `servingPlmnid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------------------------------------------------------ --
-- Session Management Subscription Data
-- ------------------------------------------------------------------ --
CREATE TABLE IF NOT EXISTS `SessionManagementSubscriptionData` (
  `id`                         int          NOT NULL AUTO_INCREMENT,
  `ueid`                       varchar(15)  NOT NULL,
  `servingPlmnid`              varchar(15)  NOT NULL,
  `singleNssai`                json         NOT NULL,
  `dnnConfigurations`          json         DEFAULT NULL,
  `internalGroupIds`           json         DEFAULT NULL,
  `sharedVnGroupDataIds`       json         DEFAULT NULL,
  `sharedDnnConfigurationsId`  varchar(50)  DEFAULT NULL,
  `odbPacketServices`          json         DEFAULT NULL,
  `traceData`                  json         DEFAULT NULL,
  `sharedTraceDataId`          varchar(50)  DEFAULT NULL,
  `expectedUeBehavioursList`   json         DEFAULT NULL,
  `suggestedPacketNumDlList`   json         DEFAULT NULL,
  `3gppChargingCharacteristics` varchar(4)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ueid_plmn` (`ueid`, `servingPlmnid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------------------------------------------------------ --
-- SMF Registration
-- ------------------------------------------------------------------ --
CREATE TABLE IF NOT EXISTS `SmfRegistrations` (
  `ueid`                       varchar(15)  NOT NULL,
  `subpduSessionId`            int(11)      NOT NULL,
  `supportedFeatures`          varchar(50)  DEFAULT NULL,
  `pduSessionId`               int(11)      DEFAULT NULL,
  `singleNssai`                json         NOT NULL,
  `dnn`                        varchar(50)  DEFAULT NULL,
  `emergencyServiceInd`        tinyint(1)   DEFAULT NULL,
  `pcscfRestorationCallbackUri` varchar(200) DEFAULT NULL,
  `plmnId`                     json         NOT NULL,
  `pgwFqdn`                    varchar(100) DEFAULT NULL,
  `pgwIpAddress`               json         DEFAULT NULL,
  `epdgInd`                    tinyint(1)   DEFAULT NULL,
  `deregCallbackUri`           varchar(200) DEFAULT NULL,
  `registrationReason`         json         DEFAULT NULL,
  `registrationTime`           varchar(50)  DEFAULT NULL,
  `contextInfo`                json         DEFAULT NULL,
  PRIMARY KEY (`ueid`, `subpduSessionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------------------------------------------------------ --
-- SMF Selection Subscription Data
-- ------------------------------------------------------------------ --
CREATE TABLE IF NOT EXISTS `SmfSelectionSubscriptionData` (
  `ueid`                       varchar(15)  NOT NULL,
  `servingPlmnid`              varchar(15)  NOT NULL,
  `supportedFeatures`          varchar(50)  DEFAULT NULL,
  `subscribedSnssaiInfos`      json         DEFAULT NULL,
  `sharedSnssaiInfosId`        varchar(50)  DEFAULT NULL,
  PRIMARY KEY (`ueid`, `servingPlmnid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ------------------------------------------------------------------ --
-- Pre-inserted subscribers: UE1 to UE8
--
-- PLMN : 208/95
-- Key  : 0C0A34601D4F07677303652C0462535B
-- OPC  : 63bfa50ee6523365ff14c1f45f88737d
-- DNN  : oai
-- SST=1, SD=1
-- ------------------------------------------------------------------ --

INSERT INTO `AuthenticationSubscription` VALUES
('208950000000031','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL),
('208950000000032','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL),
('208950000000033','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL),
('208950000000034','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL),
('208950000000035','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL),
('208950000000036','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL),
('208950000000037','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL),
('208950000000038','5G_AKA','0C0A34601D4F07677303652C0462535B','0C0A34601D4F07677303652C0462535B','{"sqn": "000000000020", "sqnScheme": "NON_TIME_BASED", "lastIndexes": {"ausf": 0}}','8000','milenage',NULL,'63bfa50ee6523365ff14c1f45f88737d',NULL,NULL,NULL);

INSERT INTO `AccessAndMobilitySubscriptionData` VALUES
('208950000000031','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000032','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000033','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000034','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000035','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000036','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000037','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000038','20895',NULL,NULL,NULL,NULL,'{"uplink": "1 Gbps", "downlink": "1 Gbps"}','{"defaultSingleNssais": [{"sst": 1, "sd": "000001"}], "singleNssais": [{"sst": 1, "sd": "000001"}]}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

INSERT INTO `SessionManagementSubscriptionData` VALUES
('208950000000031','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000032','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000033','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000034','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000035','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000036','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000037','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),
('208950000000038','20895','{"sst": 1, "sd": "000001"}','{"oai":{"pduSessionTypes":{"defaultSessionType":"IPV4"},"sscModes":{"defaultSscMode":"SSC_MODE_1"},"5gQosProfile":{"5qi":9,"arp":{"priorityLevel":15,"preemptCap":"NOT_PREEMPT","preemptVuln":"PREEMPTABLE"},"priorityLevel":1},"sessionAmbr":{"uplink":"200Mbps","downlink":"400Mbps"},"staticIpAddress":[]}}',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);