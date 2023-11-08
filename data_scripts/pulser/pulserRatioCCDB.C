#define FMT_HEADER_ONLY
#include <string_view>
#include <string>
#include <fmt/format.h>
#include <vector>

#include "TTree.h"
#include "TStyle.h"
#include "TChain.h"
#include "TCut.h"
#include "TCanvas.h"
#include "TH2Poly.h"
#include "TLatex.h"
#include "TPaletteAxis.h"

#include "TPCBase/Painter.h"
#include "TPCBase/Utils.h"
#include "TPCBase/CalDet.h"
#include "CCDB/BasicCCDBManager.h"

using namespace o2::tpc;

TTree* mCalibTree = nullptr;

void drawSideHists(const o2::tpc::CalDet<float>& calPad, const std::string& name, bool saveCanvases = false, float zMin = 0.5, float zMax = 2);
void adjustPalette(TH1* h, float x2ndc = 0.9);

void setStyle()
{
  gStyle->SetTitleOffset(1, "XY");
  gStyle->SetTitleSize(0.05, "XY");
  gStyle->SetStatX(0.9);
  gStyle->SetStatY(0.9);
  gStyle->SetOptStat("mr");
  gStyle->SetStatX(0.9);
  gStyle->SetStatW(0.3);
}

void pulserRatioCCDB(long nominatorTime, long denominatorTime, std::string name, float min = 0.5, float max = 1.5, std::string nominatorPath = "Pulser", std::string denominatorPath = "Pulser", bool saveCanvases = false, std::string_view storage = "http://ccdb-test.cern.ch:8080")
{
  using CalPadMapType = std::unordered_map<std::string, CalPad>;
  auto& cdb = o2::ccdb::BasicCCDBManager::instance();
  cdb.setURL(storage.data());
  o2::tpc::CalDet<float> calDetNominator;
  if (nominatorPath == "Pulser") {
    calDetNominator = (*cdb.getForTimeStamp<CalPadMapType>(("TPC/Calib/" + nominatorPath).data(), nominatorTime))["Qtot"];
  } else {
    calDetNominator = *cdb.getForTimeStamp<o2::tpc::CalDet<float>>(("TPC/Calib/" + nominatorPath).data(), nominatorTime);
  }
  if (denominatorPath == "Pulser") {
    auto calDetDenominator = (*cdb.getForTimeStamp<CalPadMapType>(("TPC/Calib/" + denominatorPath).data(), denominatorTime))["Qtot"];
    calDetNominator /= calDetDenominator;
  } else {
    auto calDetDenominator = *cdb.getForTimeStamp<o2::tpc::CalDet<float>>(("TPC/Calib/" + denominatorPath).data(), denominatorTime);
    calDetNominator /= calDetDenominator;
  }

  setStyle();
  drawSideHists(calDetNominator, name, saveCanvases, min, max);
}

void drawSideHists(const o2::tpc::CalDet<float>& calPad, const std::string& name, bool saveCanvases, float zMin, float zMax)
{
  TString nameAdd(name.data());
  nameAdd.ReplaceAll(" ", "_");
  nameAdd.ReplaceAll("/", "_");

  std::vector<TCanvas*> canv;
  canv.emplace_back(new TCanvas(fmt::format("c_{}", nameAdd).data(), nameAdd.Data(), 1000, 1000));
  canv[0]->Divide(2, 2);

  auto hA = painter::makeSideHist(Side::A);
  auto hC = painter::makeSideHist(Side::C);
  auto hA1D = new TH1F(fmt::format("h_{}_A_Side_1D;ADC counts", nameAdd).data(), (name + ";ADC counts").data(), 200, zMin, zMax);
  auto hC1D = new TH1F(fmt::format("h_{}_C_Side_1D;ADC counts", nameAdd).data(), (name + ";ADC counts").data(), 200, zMin, zMax);

  hA->GetZaxis()->SetRangeUser(zMin, zMax);
  hC->GetZaxis()->SetRangeUser(zMin, zMax);
  hA->SetStats(0);
  hC->SetStats(0);

  hA->SetNameTitle(fmt::format("h_{}_A_Side", nameAdd).data(), (name + ";#it{x} (cm);#it{y} (cm);ADC counts").data());
  hC->SetNameTitle(fmt::format("h_{}_C_Side", nameAdd).data(), (name + ";#it{x} (cm);#it{y} (cm);ADC counts").data());

  // fill 2D histograms
  painter::fillPoly2D(*hA, calPad, Side::A);
  painter::fillPoly2D(*hC, calPad, Side::C);

  // fill 1D histograms
  for (ROC roc; !roc.looped(); ++roc) {
    auto hist1D = hA1D;
    if (roc.side() == Side::C) {
      hist1D = hC1D;
    }

    const auto& calROC = calPad.getCalArray(roc);

    for (const auto val : calROC.getData()) {
      hist1D->Fill(val);
    }
  }

  canv[0]->cd(1);
  hA->Draw("colz");
  painter::drawSectorsXY(Side::A);
  gPad->Modified();
  gPad->Update();
  adjustPalette(hA, 0.92);

  canv[0]->cd(2);
  hC->Draw("colz");
  painter::drawSectorsXY(Side::C);
  gPad->Modified();
  gPad->Update();
  adjustPalette(hC, 0.92);

  canv[0]->cd(3);
  hA1D->Draw();
  gPad->SetLogy();

  canv[0]->cd(4);
  hC1D->Draw();
  gPad->SetLogy();

  if (saveCanvases) {
    utils::saveCanvases(canv, "fig", "png");
  }
}

void adjustPalette(TH1* h, float x2ndc)
{
  gPad->Modified();
  gPad->Update();
  auto palette = (TPaletteAxis*)h->GetListOfFunctions()->FindObject("palette");
  palette->SetX2NDC(x2ndc);
  auto ax = h->GetZaxis();
  ax->SetTickLength(0.015);
}
