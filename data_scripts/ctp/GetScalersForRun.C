// Copyright 2019-2020 CERN and copyright holders of ALICE O2.
// See https://alice-o2.web.cern.ch/copyright for details of the copyright holders.
// All rights not expressly granted are reserved.
//
// This software is distributed under the terms of the GNU General Public
// License v3 (GPL Version 3), copied verbatim in the file "COPYING".
//
// In applying this license CERN does not waive the privileges and immunities
// granted to it by virtue of its status as an Intergovernmental Organization
// or submit itself to any jurisdiction.

//#if !defined(__CLING__) || defined(__ROOTCLING__)
#include <CCDB/BasicCCDBManager.h>
#include <DataFormatsCTP/Configuration.h>
#include <DataFormatsParameters/GRPLHCIFData.h>
//#endif
#include <TMath.h>
using namespace o2::ctp;


void GetScalersForRun(string runNumberList, int fillN = 0, bool PbPb_run=true)
{
	std::size_t posOpen = runNumberList.find("[");
    std::size_t posClose = runNumberList.find("]");
	runNumberList.erase(posClose,1);
	runNumberList.erase(posOpen,1);
	
	std::string delimiter = ",";
	string token;
	size_t pos = 0;
	vector<int> runNumbers;
	while ((pos = runNumberList.find(delimiter)) != std::string::npos) {
		token = runNumberList.substr(0, pos);
		std::cout << token << std::endl;
		runNumberList.erase(0, pos + delimiter.length());
		runNumbers.push_back(stoi(token));
	}
	runNumbers.push_back(stoi(runNumberList));
	std::cout << "Number of run: "<<runNumbers.size()<<endl;
	
	std::string mCCDBPathCTPScalers = "CTP/Calib/Scalers";
	std::string mCCDBPathCTPConfig = "CTP/Config/Config";
	auto& ccdbMgr = o2::ccdb::BasicCCDBManager::instance();
	uint64_t timeStamp=0;
	vector<uint64_t> timeStamp_list;
	for(uint j=0;j<runNumbers.size();j++){
			auto soreor = ccdbMgr.getRunDuration(runNumbers[j],false);	
			cout<<"Run: "<<runNumbers[j]<<" "<<soreor.second<<" "<<soreor.first<<" "<<timeStamp<<endl;
			uint64_t timeStamp_temp = 0;
			if(soreor.second>0 && soreor.first>0)timeStamp_temp=(soreor.second - soreor.first) / 2 + soreor.first;
			timeStamp_list.push_back(timeStamp_temp );
			if(timeStamp_temp > 0 && timeStamp==0 ) timeStamp=timeStamp_temp;
	}
	std::cout << "Timestamp:" << timeStamp << std::endl;
	if(timeStamp==0){
		for(uint j=0;j<runNumbers.size();j++){
			std::cout << runNumbers[j] << "-ZNC:";
			std::cout << "Rate:" << 0 << " Integral:" << 0 << " mu:" << 0 << " Pileup prob:" << 0;
			std::cout << " Integralpp:" << 0 << " Ratepp:" << 0 << std::endl;
		}
		return;
	}
	//
	std::string sfill = std::to_string(fillN);
	std::map<string, string> metadata;
	metadata["fillNumber"] = sfill;
	auto lhcifdata = ccdbMgr.getSpecific<o2::parameters::GRPLHCIFData>("GLO/Config/GRPLHCIF", timeStamp, metadata);
	auto bfilling = lhcifdata->getBunchFilling();
	std::vector<int> bcs = bfilling.getFilledBCs();
	std::cout << "Number of interacting bc:" << bcs.size() << std::endl;
	//
	ccdbMgr.setURL("http://ccdb-test.cern.ch:8080");
	std::cout << " Get all run for that fill " << endl;
	for(uint j=0;j<runNumbers.size();j++){
		std::string srun = std::to_string(runNumbers[j]);
		metadata.clear(); // can be empty
		metadata["runNumber"] = srun;
		ccdbMgr.setFatalWhenNull(false);
		auto ctpscalers = ccdbMgr.getSpecific<CTPRunScalers>(mCCDBPathCTPScalers, timeStamp_list[j], metadata);
		if (ctpscalers == nullptr) {
			LOG(info) << "CTPRunScalers not in database, timestamp:" <<  timeStamp_list[j];
			std::cout << runNumbers[j] << "-ZNC:";
			std::cout << "Rate:" << 0 << " Integral:" << 0 << " mu:" << 0 << " Pileup prob:" << 0;
			std::cout << " Integralpp:" << 0 << " Ratepp:" << 0 << std::endl;
			continue;
		}		
		
		auto ctpcfg = ccdbMgr.getSpecific<CTPConfiguration>(mCCDBPathCTPConfig,  timeStamp_list[j], metadata);
		if (ctpcfg == nullptr) {
			LOG(info) << "CTPRunConfig not in database, timestamp:" <<  timeStamp_list[j];
			continue;
		}
		std::cout << "all good" << std::endl;
		if(runNumbers[j])>544448){
			ctpscalers->convertRawToO2();
			std::vector<CTPClass> ctpcls = ctpcfg->getCTPClasses();
			// std::vector<int> clslist = ctpcfg->getTriggerClassList();
			std::vector<uint32_t> clslist = ctpscalers->getClassIndexes();
			std::map<int, int> clsIndexToScaler;
			std::cout << "Classes:";
			int i = 0;
			for (auto const& cls : clslist) {
				std::cout << cls << " ";
				clsIndexToScaler[cls] = i;
				i++;
			}
			std::cout << std::endl;
			int tsc = 255;
			int tce = 255;
			int vch = 255;
			int iznc = 255;
			for (auto const& cls : ctpcls) {
				if (cls.name.find("CMTVXTSC-B-NOPF-CRU") != std::string::npos) {
					tsc = cls.getIndex();
					std::cout << cls.name << ":" << tsc << std::endl;
				}
				if (cls.name.find("CMTVXTCE-B-NOPF-CRU") != std::string::npos) {
					tce = cls.getIndex();
					std::cout << cls.name << ":" << tce << std::endl;
				}
				if (cls.name.find("CMTVXVCH-B-NOPF-CRU") != std::string::npos) {
					vch = cls.getIndex();
					std::cout << cls.name << ":" << vch << std::endl;
				}
				// if (cls.name.find("C1ZNC-B-NOPF-CRU") != std::string::npos) {
				if (cls.name.find("C1ZNC-B-NOPF") != std::string::npos) {
					iznc = cls.getIndex();
					std::cout << cls.name << ":" << iznc << std::endl;
				}
			}
		
		
			double_t nbc = bcs.size();
			double_t frev = 11245;
			double_t sigmaratio = 28.;
			double_t time0 = 0.;
			double_t timeL = 0.;
			double_t Trun = 0.;
			double_t integral = 0.;
			double_t rate = 0.;
			double_t rat =  0.;
			double_t mu = 0.;
			double_t pp =  0.;
			double_t ratepp =  0.;
			double_t integralpp = 0.;
		
		
			std::vector<CTPScalerRecordO2> recs = ctpscalers->getScalerRecordO2();
		
			int inp = 26;
			if (recs[0].scalersInps.size() == 48) {
				time0 = recs[0].epochTime;
				timeL = recs[recs.size() - 1].epochTime;
				Trun = timeL - time0;
				integral = recs[recs.size() - 1].scalersInps[inp - 1] - recs[0].scalersInps[inp - 1];
				rate = integral / Trun;
				rat = integral / Trun / nbc / frev;
				mu = -TMath::Log(1 - rat);
				pp = 1 - mu / (TMath::Exp(mu) - 1);
				ratepp = mu * nbc * frev;
				integralpp = ratepp * Trun;
			}
			std::cout << runNumbers[j] << "-ZNC:";
			std::cout << "Rate:" << rate / sigmaratio << " Integral:" << integral << " mu:" << mu << " Pileup prob:" << pp;
			std::cout << " Integralpp:" << integralpp << " Ratepp:" << ratepp / sigmaratio << std::endl;
		
			inp = 2;
			if (recs[0].scalersInps.size() == 48) {
				time0 = recs[0].epochTime;
				timeL = recs[recs.size() - 1].epochTime;
				Trun = timeL - time0;
				integral = recs[recs.size() - 1].scalersInps[inp - 1] - recs[0].scalersInps[inp - 1];
				rate = integral / Trun;
				rat = integral / Trun / nbc / frev;
				mu = -TMath::Log(1 - rat);
				pp = 1 - mu / (TMath::Exp(mu) - 1);
				ratepp = mu * nbc * frev;
				integralpp = ratepp * Trun;
			}
			std::cout << runNumbers[j] << "-FT0:";
			std::cout << "Rate:" << rate / sigmaratio << " Integral:" << integral << " mu:" << mu << " Pileup prob:" << pp;
			std::cout << " Integralpp:" << integralpp << " Ratepp:" << ratepp / sigmaratio << std::endl;
		
			if (tsc != 255) {
				std::cout << "TSC:";
				ctpscalers->printClassBRateAndIntegral(clsIndexToScaler[tsc] + 1);
			}
			if (tce != 255) {
				std::cout << "TCE:";
				ctpscalers->printClassBRateAndIntegral(clsIndexToScaler[tce] + 1);
			}
			// std::cout << "TCE input:" << ctpscalers->printInputRateAndIntegral(5) << std::endl;;
			if (vch != 255) {
				std::cout << "VCH:";
				ctpscalers->printClassBRateAndIntegral(clsIndexToScaler[vch] + 1);
			}
			if (iznc != 255) {
				std::cout << "ZNC class:";
				// uint64_t integral = recs[recs.size() - 1].scalers[iznc].l1After - recs[0].scalers[iznc].l1After;
				auto zncrate = ctpscalers->getRateGivenT(0, iznc, 6);
				std::cout << "ZNC class rate:" << zncrate.first / 28. << std::endl;
			} else {
			std::cout << "ZNC class not available" << std::endl;
			}
		}
	}
}
