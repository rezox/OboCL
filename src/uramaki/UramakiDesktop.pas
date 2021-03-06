// This is part of the Obo Component Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)
unit UramakiDesktop;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, Controls, ComCtrls, Graphics, Menus, contnrs, ExtCtrls, Forms,

  oMultiPanelSetup,
  mXML,

  UramakiBase, UramakiEngine, UramakiEngineClasses,
  UramakiDesktopGUI, UramakiDesktopLayout,
  UramakiDesktopLayoutLCLConfigForm, UramakiDesktopLCLIcons;

type

  { TUramakiDesktopManager }

  TUramakiDesktopManager = class
  strict private
    FEngine : TUramakiEngine;
    FParentControl : TWinControl;
    FContainer : TUramakiDesktopContainerPanel;
    FDesktopDataModule: TUramakiDesktopDataModule;
    FMenuGarbageCollector : TObjectList;


//    procedure CreateToolbar;
    procedure BuildAndFeedPlate(aLivingPlate: TUramakiLivingPlate; aItem: TPanel);
    procedure OnAddPlate (Sender : TObject);
    procedure DoLinkLayoutItemToPlate(aItem : TPanel; aLivingPlateInstanceIdentificator : TGuid);
    procedure DoStartShiningPanel(const aPlate : TUramakiLivingPlate);
    procedure DoStopShiningPanel(const aPlate : TUramakiLivingPlate);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Init (aParent : TWinControl);

    procedure AddPublisher (aPublisher : TUramakiPublisher);
    procedure AddTransformer (aTransformer : TUramakiTransformer);

    procedure LoadFromStream (aStream : TStream);
    procedure SaveToStream (aStream : TStream);
    procedure ShowConfigurationForm;
    procedure FillAddWidgetMenu (aMenuItem : TMenuItem; const aInputUramakiId : string; aLivingPlateIdentifier : TGuid);
  end;

implementation

uses
  SysUtils, Dialogs;

type
  TMenuInfo = class
  public
    LivingPlateIdenfier : TGuid;
    TransformerId : string;
    PublisherId : string;
  end;

{ TUramakiDesktopManager }

{
procedure TUramakiDesktopManager.CreateToolbar;
begin
//  FToolbar.AddButton(ICON_ADD, nil, '', '', '', false);
  FToolbar.AddDropdown(FRootPopupMenu, nil, 'Add...');
  FToolbar.AddButton(ICON_OPEN, OnLoadFromFile, '', 'Open a report file..', '', false);
  FToolbar.AddButton(ICON_SAVE, OnSaveToFile, '', 'Save to a report file...', '', false);
  FToolbar.AddButton(ICON_CONFIGURE, OnConfigureLayout, '', 'Configure layout of report', '', false);
  FToolbar.UpdateControls;

*)
end;}


procedure TUramakiDesktopManager.OnAddPlate(Sender: TObject);
var
  tmpMenuInfo : TMenuInfo;
  item : TUramakiDesktopSimplePanel;
  tmpLivingPlate : TUramakiLivingPlate;
begin
  tmpMenuInfo := TMenuInfo((Sender as TMenuItem).Tag);
  item := FContainer.AddItem;
  tmpLivingPlate := FEngine.CreateLivingPlate(tmpMenuInfo.LivingPlateIdenfier);
  item.LivingPlateInstanceIdentifier := tmpLivingPlate.InstanceIdentifier;
  if tmpMenuInfo.TransformerId <> '' then
    tmpLivingPlate.Transformations.Add.Transformer := FEngine.FindTransformer(tmpMenuInfo.TransformerId);
  tmpLivingPlate.Publication.Publisher := FEngine.FindPublisher(tmpMenuInfo.PublisherId);
  item.TabData.TabCaption:= tmpLivingPlate.Publication.Publisher.GetDescription;
  item.TabData.TabColor:= DEFAULT_TAB_COLOR;

  BuildAndFeedPlate(tmpLivingPlate, item);
end;

procedure TUramakiDesktopManager.BuildAndFeedPlate(aLivingPlate : TUramakiLivingPlate; aItem: TPanel);
var
  parentRolls : TStringList;
  i : integer;
begin
  if Assigned(aLivingPlate.Publication) and Assigned(aLivingPlate.Publication.Publisher) then
  begin
    aLivingPlate.Plate := aLivingPlate.Publication.Publisher.CreatePlate(aItem);
    aLivingPlate.Plate.Parent := aItem;
    aLivingPlate.Plate.Align := alClient;
    aLivingPlate.Plate.EngineMediator := FEngine.Mediator;
    aLivingPlate.DoPlateStartShining := Self.DoStartShiningPanel;
    aLivingPlate.DoPlateStopShining:= Self.DoStopShiningPanel;

    if aItem is TUramakiDesktopSimplePanel then
    begin
      (aItem as TUramakiDesktopSimplePanel).AddMenuItem.Clear;
      parentRolls := TStringList.Create;
      try
        aLivingPlate.Plate.GetAvailableUramakiRolls(parentRolls);
        if parentRolls.Count > 0 then
        begin
          for i := 0 to parentRolls.Count - 1 do
          begin
            Self.FillAddWidgetMenu((aItem as TUramakiDesktopSimplePanel).AddMenuItem, parentRolls.Strings[i], aLivingPlate.InstanceIdentifier);
          end;
        end;
      finally
        parentRolls.Free;
      end;
    end;
    FEngine.FeedLivingPlate(aLivingPlate);
  end;
end;

procedure TUramakiDesktopManager.DoLinkLayoutItemToPlate(aItem: TPanel; aLivingPlateInstanceIdentificator: TGuid);
var
  tmpLivingPlate : TUramakiLivingPlate;
begin
  tmpLivingPlate := FEngine.FindLivingPlateByPlateId(aLivingPlateInstanceIdentificator);
  if Assigned(tmpLivingPlate) then
    BuildAndFeedPlate(tmpLivingPlate, aItem);
end;

procedure TUramakiDesktopManager.DoStartShiningPanel(const aPlate : TUramakiLivingPlate);
begin
  if (aPlate.Plate.Parent is TUramakiDesktopSimplePanel) then
  begin
    (aPlate.Plate.Parent as TUramakiDesktopSimplePanel).StartShining;
  end;
end;

procedure TUramakiDesktopManager.DoStopShiningPanel(const aPlate: TUramakiLivingPlate);
begin
  if (aPlate.Plate.Parent is TUramakiDesktopSimplePanel) then
  begin
    (aPlate.Plate.Parent as TUramakiDesktopSimplePanel).StopShining;
  end;
end;

constructor TUramakiDesktopManager.Create;
begin
  FEngine := TUramakiEngine.Create;
  FDesktopDataModule:= TUramakiDesktopDataModule.Create(nil);
  FMenuGarbageCollector := TObjectList.Create(true);
end;

destructor TUramakiDesktopManager.Destroy;
begin
  FreeAndNil(FEngine);
  FreeAndNil(FDesktopDataModule);
  FreeAndNil(FMenuGarbageCollector);
  inherited Destroy;
end;

procedure TUramakiDesktopManager.Init(aParent : TWinControl);
begin
  FParentControl := aParent;

  FContainer := TUramakiDesktopContainerPanel.Create(FParentControl);
  FContainer.Parent := FParentControl;
  FContainer.Init(ctHorizontal);
  FContainer.Align:= alClient;
end;

procedure TUramakiDesktopManager.AddPublisher(aPublisher: TUramakiPublisher);
begin
  FEngine.AddPublisher(aPublisher);
end;

procedure TUramakiDesktopManager.AddTransformer(aTransformer: TUramakiTransformer);
begin
  FEngine.AddTransformer(aTransformer);
end;

procedure TUramakiDesktopManager.LoadFromStream(aStream : TStream);
var
  doc : TmXmlDocument;
  cursor : TmXmlElementCursor;
  tmp : TUramakiDesktopLayoutConfContainerItem;
begin
  doc := TmXmlDocument.Create;
  try
    doc.LoadFromStream(aStream);

    cursor := TmXmlElementCursor.Create(doc.RootElement, 'livingPlates');
    try
      FEngine.LoadLivingPlatesFromXMLElement(cursor.Elements[0]);
    finally
      cursor.Free;
    end;

    cursor := TmXmlElementCursor.Create(doc.RootElement, 'layout');
    try
      tmp := TUramakiDesktopLayoutConfContainerItem.Create;
      try
        tmp.LoadFromXMLElement(cursor.Elements[0]);
        FContainer.ImportFromConfItem(tmp, Self.DoLinkLayoutItemToPlate);
      finally
        tmp.Free;
      end;
    finally
      cursor.Free;
    end;

    cursor := TmXmlElementCursor.Create(doc.RootElement, 'plates');
    try
      if Cursor.Count > 0 then
        FEngine.LoadPlatesFromXMLElement(Cursor.Elements[0]);
    finally
      cursor.Free;
    end;

  finally
    doc.Free;
  end;
end;

procedure TUramakiDesktopManager.SaveToStream(aStream : TStream);
var
  doc : TmXmlDocument;
  root : TmXmlElement;
  tmp : TUramakiDesktopLayoutConfItem;
begin
  doc := TmXmlDocument.Create;
  try
    root := doc.CreateRootElement('uramakiReport');
    root.SetIntegerAttribute('version', 1);
    tmp := FContainer.ExportAsConfItem;
    try
      tmp.SaveToXMLElement(root.AddElement('layout'));
      FEngine.SaveLivingPlatesToXMLElement(root.AddElement('livingPlates'));
      FEngine.SavePlatesToXMLElement(root.AddElement('plates'));

      doc.SaveToStream(aStream);
    finally
      tmp.Free;
    end;
  finally
    doc.Free;
  end;
end;

procedure TUramakiDesktopManager.ShowConfigurationForm;
var
  Dlg : TDesktopLayoutConfigForm;
  tmpConfItem, tmpConfItemOut : TUramakiDesktopLayoutConfItem;
  fakeDocument : TmXmlDocument;
  oldCursor : TCursor;
begin
  Dlg := TDesktopLayoutConfigForm.Create(nil);
  try
    tmpConfItem := FContainer.ExportAsConfItem;
    try
      Dlg.Init(tmpConfItem);
      if Dlg.ShowModal = mrOk then
      begin
        oldCursor := Screen.Cursor;
        try
          Screen.Cursor:= crHourGlass;
          tmpConfItemOut := Dlg.ExtractModifiedLayout;
          try
            assert (tmpConfItemOut is TUramakiDesktopLayoutConfContainerItem);
            fakeDocument := TmXmlDocument.Create;
            try
              FEngine.SavePlatesToXMLElement(fakeDocument.CreateRootElement('root'));
              FContainer.ImportFromConfItem(tmpConfItemOut, Self.DoLinkLayoutItemToPlate);
              FEngine.LoadPlatesFromXMLElement(fakeDocument.RootElement);
            finally
              fakeDocument.Free;
            end;
          finally
            tmpConfItemOut.Free;
          end;
        finally
          Screen.Cursor:= oldCursor;
        end;
      end;
    finally
      tmpConfItem.Free;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TUramakiDesktopManager.FillAddWidgetMenu(aMenuItem: TMenuItem; const aInputUramakiId : string; aLivingPlateIdentifier : TGuid);
var
  i, j : integer;
  tempListOfTransformers : TUramakiTransformers;
  tempListOfPublishers : TUramakiPublishers;
  mt, mt2 : TMenuItem;
  tmpMenuInfo : TMenuInfo;
begin
  if not Assigned(aMenuItem) then
    exit;

  //aMenuItem.Clear;

  tempListOfTransformers := TUramakiTransformers.Create;
  tempListOfPublishers := TUramakiPublishers.Create;
  try

    // publishers without transformers
    FEngine.GetAvailablePublishers(aInputUramakiId, tempListOfPublishers);
    if tempListOfPublishers.Count > 0 then
    begin
      for j := 0 to tempListOfPublishers.Count - 1 do
      begin
        mt2 := TMenuItem.Create(aMenuItem);
        mt2.Caption := tempListOfPublishers.Get(j).GetDescription;
        aMenuItem.Add(mt2);
        mt2.OnClick:= Self.OnAddPlate;
        tmpMenuInfo := TMenuInfo.Create;
        tmpMenuInfo.PublisherId:= tempListOfPublishers.Get(j).GetMyId;
        tmpMenuInfo.TransformerId:= '';
        tmpMenuInfo.LivingPlateIdenfier := aLivingPlateIdentifier;
        mt2.Tag:= PtrInt(tmpMenuInfo);
        FMenuGarbageCollector.Add(tmpMenuInfo);
      end;
    end;

    // root transformers
    FEngine.GetAvailableTransformers(aInputUramakiId, tempListOfTransformers);
    for i := 0 to tempListOfTransformers.Count -1 do
    begin
      FEngine.GetAvailablePublishers(tempListOfTransformers.Get(i).GetOutputUramakiId, tempListOfPublishers);
      if tempListOfPublishers.Count > 0 then
      begin
        mt := TMenuItem.Create(aMenuItem);
        mt.Caption:= tempListOfTransformers.Get(i).GetDescription;
        aMenuItem.Add(mt);
        for j := 0 to tempListOfPublishers.Count - 1 do
        begin
          mt2 := TMenuItem.Create(aMenuItem);
          mt2.Caption := tempListOfPublishers.Get(j).GetDescription;
          mt.Add(mt2);
          mt2.OnClick:= Self.OnAddPlate;
          tmpMenuInfo := TMenuInfo.Create;
          tmpMenuInfo.PublisherId:= tempListOfPublishers.Get(j).GetMyId;
          tmpMenuInfo.TransformerId:= tempListOfTransformers.Get(i).GetMyId;
          tmpMenuInfo.LivingPlateIdenfier := aLivingPlateIdentifier;
          mt2.Tag:= PtrInt(tmpMenuInfo);
          FMenuGarbageCollector.Add(tmpMenuInfo);
        end;
      end;
    end;
  finally
    tempListOfPublishers.Free;
    tempListOfTransformers.Free;
  end;
end;


end.
