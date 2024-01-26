#include <chrono>
#include <fmt/format.h>
#include "rapidjson/document.h"
#include "CCDB/CcdbApi.h"
#include "TSystem.h"
#include "TStyle.h"
#include "CCDB/BasicCCDBManager.h"
#include "DataFormatsTPC/VDriftCorrFact.h"
#include "TGraph.h"
#include "TCanvas.h"
#include "TH1.h"

o2::ccdb::CcdbApi mCcdbApi;

// if startTimeOrRun < 1000000 then a run number is assumed, if only the first value us given, then it is a single run
// if both, startTimeOrRun < 0 and endTimeOrRun are -1, then interpret startTimeOrRun number of minutes before now
void drawVDTgl(long startTimeOrRun = -24 * 60, long endTimeOrRun = -1)
{
  mCcdbApi.init("http://alice-ccdb.cern.ch");
  std::string_view path("TPC/Calib/VDriftTgl");
  int runNumber_set=-1;
  auto& ccdbMan = o2::ccdb::BasicCCDBManager::instance();
  ccdbMan.setURL("https://alice-ccdb.cern.ch");
  // assume run numbers
  if (startTimeOrRun > -1 && startTimeOrRun < 1000000 && endTimeOrRun < 1000000) {
    runNumber_set=startTimeOrRun;
    if (endTimeOrRun == -1) {
      endTimeOrRun = startTimeOrRun;
      
    }

    auto runRangeStart = ccdbMan.getRunDuration(startTimeOrRun);
    auto runRangeEnd = ccdbMan.getRunDuration(endTimeOrRun);

    startTimeOrRun = runRangeStart.first;
    endTimeOrRun = runRangeEnd.second;
  }

  if (startTimeOrRun < 0 && endTimeOrRun == -1) {
    startTimeOrRun = std::chrono::duration_cast<std::chrono::milliseconds>((std::chrono::system_clock::now() + std::chrono::minutes(startTimeOrRun)).time_since_epoch()).count();
    endTimeOrRun = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
  }

  // try up to nTrial times in case we get a server error
  std::string json;
  const int nTrial = 10;
  bool gotList = false;
  for (int i = 0; i < nTrial; ++i) {
    try {
      json = mCcdbApi.list(path.data(), false, "application/json");
      gotList = true;
    } catch (...) {
      gotList = false;
    }
    if (gotList && (json.substr(0, 20).find("doctype html") == std::string::npos)) {
      break;
    }
    fmt::print("Failed to get list for {} trial {} / {}, error: {} ...\n", path, i, nTrial, json.substr(0, 100));
    gSystem->Sleep(10);
  }

  rapidjson::Document doc;
  doc.Parse(json.data());

  if (!doc.IsObject() || !doc.HasMember("objects") || !doc["objects"].IsArray()) {
    throw std::runtime_error(fmt::format("could not parse object list for {}", path));
  }

  auto entries = doc["objects"].GetArray();
  LOGP(info, "Found {} entries for object {}", entries.Size(), path);

  // remove elements outside the range, or not spanning the range
  entries.Erase(std::remove_if(entries.begin(), entries.end(), [startTimeOrRun, endTimeOrRun](const auto& entry) {
                  const auto startValidity = entry["validFrom"].GetInt64();
                  const auto endValidity = entry["validUntil"].GetInt64();
                  return ((startValidity < startTimeOrRun) || (startValidity >= endTimeOrRun)) && !((startValidity <= startTimeOrRun) && (endValidity >= endTimeOrRun));
                }),
                entries.end());

  // sort by time
  std::sort(entries.begin(), entries.end(), [](const auto& a, const auto& b) { return a["validFrom"].GetInt64() < b["validFrom"].GetInt64(); });

  LOGP(info, "Found {} entries for object {} after filtering between {} - {}", entries.Size(), path, startTimeOrRun, endTimeOrRun);

  auto gr = new TGraph;
  for (const auto& entry : entries) {
    const auto startValidity = entry["validFrom"].GetInt64();
    if (startValidity < 1420066800000) {
      continue;
    }
    const auto endValidity = entry["validUntil"].GetInt64();
    int runNumber = 0;
    if (entry.FindMember("runNumber") != entry.MemberEnd()) {
      runNumber = std::atoi(entry["runNumber"].GetString());
    }
    std::map<std::string, std::string> mm, mm2;
    auto obj = mCcdbApi.retrieveFromTFileAny<o2::tpc::VDriftCorrFact>(path.data(), mm, startValidity, &mm2);
    if (!obj) {
      continue;
    }
    if( ( runNumber_set < 0 ) || ( runNumber_set == runNumber ) ){
      gr->AddPoint(double(startValidity / 1000.), double(obj->getVDrift()));
      fmt::print("run: {}, start: {}, vDrift: {}cm/us\n", runNumber, startValidity / 1000., obj->getVDrift());
    }
    delete obj;
  }

  gStyle->SetTimeOffset(0);
  auto cDrift = new TCanvas("cDrift");
  gr->SetMarkerStyle(20);
  gr->SetMarkerSize(1);
  gr->Draw("alp");
  cDrift->Modified();
  cDrift->Update();
  auto ax = ((TH1*)gr->GetHistogram())->GetXaxis();
  ax->SetTimeDisplay(1);
  ax->SetTimeFormat("#splitline{%d.%m.%y}{%H:%M:%S}");
  ax->SetLabelOffset(0.025);
  ax->SetLabelSize(0.05);
  ax->SetTitle("");
}
