unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DateTimePicker, Forms, Controls, Graphics,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Spin, CheckLst, EditBtn, ComboEx,
  DateUtils, Math;

type

  { TForm1 }

  TForm1 = class(TForm)
    cbNumCourts: TComboBox;
    cbNumPlayers: TComboBox;
    cbPrime1Days: TCheckComboBox;
    cbPrime2Days: TCheckComboBox;
    dtPrimeEnd2: TDateTimePicker;
    dtPrimeStart2: TDateTimePicker;
    Label10: TLabel;
    Label9: TLabel;
    lblPlayerCost: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lblTotalCost: TLabel;
    fsePrimeCost: TFloatSpinEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    fseNormalCost: TFloatSpinEdit;
    dtCourtEnd: TDateTimePicker;
    dtPrimeStart1: TDateTimePicker;
    Label1: TLabel;
    PageControl1: TPageControl;
    Cost: TTabSheet;
    dtPrimeEnd1: TDateTimePicker;
    dtCourtStart: TDateTimePicker;
    Setup: TTabSheet;
    procedure cbNumCourtsChange(Sender: TObject);
    procedure cbNumPlayersChange(Sender: TObject);
    procedure dtCourtEndChange(Sender: TObject);
    procedure dtCourtStartChange(Sender: TObject);
    procedure dtPrimeEnd1Change(Sender: TObject);
    procedure dtPrimeEnd2Change(Sender: TObject);
    procedure dtPrimeStart1Change(Sender: TObject);
    procedure dtPrimeStart2Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure fseNormalCostChange(Sender: TObject);
    procedure fsePrimeCostChange(Sender: TObject);
  private
    { private declarations }
    origTotalCostLbl: string;
    origPlayerCostLbl: string;
    primeMinutes: double;
    procedure UpdateCosts();
    procedure SetCostLabels(totalCost, playerCost: double);
    function GetPrimeTimeFraction(courtStart, courtEnd, primeStart, primeEnd: TTime;
      numMin: integer): double;
    procedure SetPrimeDaysChecked();
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  origTotalCostLbl := lblTotalCost.Caption;
  origPlayerCostLbl := lblPlayerCost.Caption;
  primeMinutes := Round(MinuteSpan(dtPrimeEnd1.Time, dtPrimeStart1.Time));
  SetPrimeDaysChecked();
  UpdateCosts();
end;

procedure TForm1.fseNormalCostChange(Sender: TObject);
begin
  if fseNormalCost.Text <> EmptyStr then
  begin
    UpdateCosts();
  end;
end;

procedure TForm1.fsePrimeCostChange(Sender: TObject);
begin
  if fsePrimeCost.Text <> EmptyStr then
  begin
    UpdateCosts();
  end;
end;

procedure TForm1.dtPrimeEnd1Change(Sender: TObject);
begin
  UpdateCosts();
end;

procedure TForm1.dtPrimeEnd2Change(Sender: TObject);
begin
  UpdateCosts();
end;

procedure TForm1.dtPrimeStart1Change(Sender: TObject);
begin
  UpdateCosts();
end;

procedure TForm1.dtPrimeStart2Change(Sender: TObject);
begin
  UpdateCosts();
end;

procedure TForm1.dtCourtStartChange(Sender: TObject);
begin
  UpdateCosts();
end;

procedure TForm1.cbNumCourtsChange(Sender: TObject);
begin
  if cbNumCourts.Text <> EmptyStr then
  begin
    UpdateCosts();
  end;
end;

procedure TForm1.cbNumPlayersChange(Sender: TObject);
begin
  if cbNumPlayers.Text <> EmptyStr then
  begin
    UpdateCosts();
  end;
end;

procedure TForm1.dtCourtEndChange(Sender: TObject);
begin
  if fsePrimeCost.Text <> EmptyStr then
  begin
    UpdateCosts();
  end;
end;

procedure TForm1.UpdateCosts;
var
  playMinutes: integer;
  totalCost, playerCost, primeFrac, normalFrac, primeCost, normalCost: double;

begin
  { make sure court time is logical, it starts before it ends }
  if dtCourtEnd.Time - dtCourtStart.Time < 0 then
  begin
    lblTotalCost.Caption := origTotalCostLbl;
    lblPlayerCost.Caption := origPlayerCostLbl;
    MessageDlg('Error - Court Time', 'Court Time starts after it ends',
      mtError, [mbOK], 0);
    Exit;
  end;

  playMinutes := Round(MinuteSpan(dtCourtEnd.Time, dtCourtStart.Time));

  { if court time is zero then cost is zero }
  if playMinutes = 0 then
  begin
    SetCostLabels(0, 0);
    Exit;
  end;

  { get the fraction of court time in prime time }
  primeFrac := GetPrimeTimeFraction(dtCourtStart.Time,
    dtCourtEnd.Time, dtPrimeStart1.Time, dtPrimeEnd1.Time, playMinutes);

  { if fraction of court time in prime time is less than zero or greater than
  one, bad error }
  if (primeFrac < 0) or (primeFrac > 1) then
  begin
    lblTotalCost.Caption := origTotalCostLbl;
    lblPlayerCost.Caption := origPlayerCostLbl;
    MessageDlg('Error', 'Contact developer, major program error.',
      mtError, [mbOK], 0);
    Exit;
  end;

  { if fraction of court time in prime time is one, court time must cover
  all, part of, or more than prime time. Otherwise, use fractional prime
  time calculation }
  if primeFrac = 1 then
  begin
    primeCost := (Min(primeMinutes, playMinutes) / 60.0) * fsePrimeCost.Value;
    normalCost := (Max(playMinutes - primeMinutes, 0) / 60.0) *
      fseNormalCost.Value;
    totalCost := (primeCost + normalCost) * StrToInt(cbNumCourts.Text);
  end
  else
  begin
    normalFrac := 1 - primeFrac;
    primeCost := primeFrac * fsePrimeCost.Value;
    normalCost := normalFrac * fseNormalCost.Value;
    totalCost := (primeCost + normalCost) * StrToInt(cbNumCourts.Text) *
      (playMinutes / 60.0);
  end;
  playerCost := totalCost / StrToInt(cbNumPlayers.Text);
  SetCostLabels(totalCost, playerCost);
end;

procedure TForm1.SetCostLabels(totalCost, playerCost: double);
begin
  lblTotalCost.Caption := origTotalCostLbl + '    ' +
    FloatToStrF(totalCost, TFloatFormat.ffCurrency, 2, 2);

  lblPlayerCost.Caption := origPlayerCostLbl + '    ' +
    FloatToStrF(playerCost, TFloatFormat.ffCurrency, 2, 2);

  lblPlayerCost.Font.Bold := True;
end;

function TForm1.GetPrimeTimeFraction(courtStart, courtEnd,
  primeStart, primeEnd: TTime; numMin: integer): double;
var
  t1, t2: TTime;

begin
  Result := 0;
  if ((courtStart <= primeStart) and (courtEnd >= primeEnd)) or
     ((courtStart > primeStart) and (courtEnd < primeEnd)) then
    Result := 1
  else
  begin
    if (courtStart <= primeStart) then
    begin
      t1 := primeStart;
      t2 := courtEnd;
    end;

    if (courtStart >= primeStart) then
    begin
      t1 := courtStart;
      t2 := primeEnd;
    end;

    Result := MinuteSpan(t2, t1) / numMin;
  end;

  { round result to three decimal places }
  Result := Round(Result * 1000) / 1000;
end;

procedure TForm1.SetPrimeDaysChecked;
var
  i: integer;

begin
  for i := 1 to 4 do
    cbPrime1Days.Checked[i] := True;
  cbPrime2Days.Checked[5] := True;

  cbPrime1Days.ItemIndex := 1;
  cbPrime2Days.ItemIndex := 5;
end;

end.
