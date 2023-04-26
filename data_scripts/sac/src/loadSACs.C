#include "CCDB/BasicCCDBManager.h"
#include "TPCCalibration/IDCContainer.h"
#include "TPCCalibration/IDCGroupHelperSector.h"
#include "TPCCalibration/IDCCCDBHelper.h"
#include "TPCCalibration/SACCCDBHelper.h"
#include "TPCBase/Painter.h"
#include "TPCBase/CDBInterface.h"
#include "TCanvas.h"

using namespace o2::tpc;

/// \param timestamp Valid from timestamp from CCDB
/// \param zmin zmin range of the IDC0 plot
/// \param zmax zmax range of the IDC0 plot

/*
 root.exe -b
.L idc_sac_CCDB.c
loadIDCs(1668652887846);

root.exe tree_idc_1668652887846.root
tree -> SetMarkerStyle(20);
tree -> SetMarkerColor(kRed);
tree -> Draw("IDC1A:Iteration$");
tree -> SetMarkerColor(kBlue);
tree -> Draw("IDC1C:Iteration$","","SAME");
*/
void loadIDCs(const long timestamp = 0, float zmin = 0, float zmax = 5, const char* path = "http://alice-ccdb.cern.ch")
{
  using namespace o2::tpc;
  o2::ccdb::BasicCCDBManager mCCDBManager = o2::ccdb::BasicCCDBManager::instance();
  mCCDBManager.setURL(path);
  mCCDBManager.setTimestamp(timestamp);
  mCCDBManager.setFatalWhenNull(false);

  using dataT = unsigned char;
  IDCDelta<dataT>* mIDCDeltaA = mCCDBManager.get<o2::tpc::IDCDelta<dataT>>(CDBTypeMap.at(CDBType::CalIDCDeltaA));
  IDCZero* mIDCZeroA = mCCDBManager.get<o2::tpc::IDCZero>(CDBTypeMap.at(CDBType::CalIDC0A));
  IDCOne* mIDCOneA = mCCDBManager.get<o2::tpc::IDCOne>(CDBTypeMap.at(CDBType::CalIDC1A));
  std::unique_ptr<IDCGroupHelperSector> mHelperSectorA = std::make_unique<IDCGroupHelperSector>(IDCGroupHelperSector{*mCCDBManager.get<o2::tpc::ParameterIDCGroupCCDB>("TPC/Calib/IDC/GROUPINGPAR/A")});

  IDCDelta<dataT>* mIDCDeltaC = mCCDBManager.get<o2::tpc::IDCDelta<dataT>>(CDBTypeMap.at(CDBType::CalIDCDeltaC));
  IDCZero* mIDCZeroC = mCCDBManager.get<o2::tpc::IDCZero>(CDBTypeMap.at(CDBType::CalIDC0C));
  IDCOne* mIDCOneC = mCCDBManager.get<o2::tpc::IDCOne>(CDBTypeMap.at(CDBType::CalIDC1C));

  IDCCCDBHelper<dataT> helper;
  if (mIDCDeltaA) {
    helper.setIDCDelta(mIDCDeltaA, Side::A);
  }
  helper.setIDCZero(mIDCZeroA, Side::A);
  helper.setIDCOne(mIDCOneA, Side::A);
  helper.setGroupingParameter(mHelperSectorA.get(), Side::A);
  if (mIDCDeltaA) {
    helper.setIDCDelta(mIDCDeltaC, Side::C);
  }
  helper.setIDCZero(mIDCZeroC, Side::C);
  helper.setIDCOne(mIDCOneC, Side::C);
  helper.setGroupingParameter(mHelperSectorA.get(), Side::C);

  helper.drawIDCZeroSide(o2::tpc::Side::A, Form("IDCZeroSideA_%li.pdf", timestamp), zmin, zmax);
  helper.drawIDCZeroSide(o2::tpc::Side::C, Form("IDCZeroSideC_%li.pdf", timestamp), zmin, zmax);

  TCanvas canRadius;
  helper.createOutlierMap();
  helper.scaleIDC0(Side::A);
  helper.scaleIDC0(Side::C);
  helper.drawIDCZeroRadialProfile(&canRadius, 100, 0, 3);
  canRadius.SaveAs(Form("IDC0_vs_radius_%li.pdf", timestamp));

  TCanvas* can1d = helper.drawIDCOneCanvas(nullptr, 100, 0.5, 1.5, -1);
  can1d->SaveAs(Form("IDC1_vs_radius_%li.pdf", timestamp));

  TCanvas canIDC0;
  helper.drawIDCZeroCanvas(&canIDC0, "IDC0", 100, 0, 3);
  canIDC0.SaveAs(Form("IDC0_Canv_%li.pdf", timestamp));

  // TCanvas canIDC0Stack;
  // helper.drawIDCZeroStackCanvas(&canIDC0Stack, Side::A, "IDC0", 100, 0, 3);
  // canIDC0Stack.SaveAs(Form("IDC0_stack_%li.pdf", timestamp));

  if (mIDCDeltaA) {
    helper.drawIDCDeltaSide(o2::tpc::Side::A, 5, "IDCDeltaSideA.pdf");
    helper.drawIDCSide(o2::tpc::Side::A, 5, "IDCsA.pdf");
  }
  if (mIDCDeltaC) {
    helper.drawIDCDeltaSide(o2::tpc::Side::C, 5, "IDCDeltaideC.pdf");
    helper.drawIDCSide(o2::tpc::Side::C, 5, "IDCsC.pdf");
  }

  std::cout << "dumping" << std::endl;
  helper.dumpToTree(Form("tree_idc_%li.root", timestamp));
  std::cout << "dumped.. .writing IDCdelta" << std::endl;

  if (mIDCDeltaA || mIDCDeltaC) {
    helper.dumpToTreeIDCDelta(Form("tree_idc_delta_%li.root", timestamp));
    std::cout << "dumped IDCDelta" << std::endl;
  }
}

/// \param timestamp Valid from timestamp from CCDB
/// \param zmin zmin range of the IDC0 plot
/* example
loadSACs(1668652887846);

root.exe SACCCDBTree_1668652887846.root
tree -> SetMarkerStyle(20);
tree -> SetMarkerColor(kRed);
tree -> Draw("SAC1A:integrationInterval");
tree -> SetMarkerColor(kBlue);
tree -> Draw("SAC1C:integrationInterval","","SAME");
new TCanvas;
tree -> Draw("SAC1A:SAC1C");
*/
void loadSACs(const long timestamp = 0, float zmin = 0, float zmax = -1, const char* path = "http://alice-ccdb.cern.ch")
{
  using dataT = unsigned char;
  using namespace o2::tpc;
  o2::ccdb::BasicCCDBManager mCCDBManager = o2::ccdb::BasicCCDBManager::instance();
  mCCDBManager.setURL(path);
  mCCDBManager.setTimestamp(timestamp);
  mCCDBManager.setFatalWhenNull(false);

  SACCCDBHelper<dataT> helperSAC;
  auto* mSACDelta = mCCDBManager.get<SACDelta<dataT>>(CDBTypeMap.at(CDBType::CalSACDelta));
  auto* mSACZero = mCCDBManager.get<o2::tpc::SACZero>(CDBTypeMap.at(CDBType::CalSAC0));
  auto* mSACOne = mCCDBManager.get<o2::tpc::SACOne>(CDBTypeMap.at(CDBType::CalSAC1));
  helperSAC.setSACDelta(mSACDelta);
  helperSAC.setSACZero(mSACZero);
  helperSAC.setSACOne(mSACOne);

  helperSAC.drawSACZeroSide(Side::A, Form("SACZeroSide_A_%li.pdf", timestamp), zmin, zmax);
  helperSAC.drawSACZeroSide(Side::C, Form("SACZeroSide_C_%li.pdf", timestamp), zmin, zmax);

  helperSAC.dumpToTree(Form("SACCCDBTree_%li.root", timestamp));
}
