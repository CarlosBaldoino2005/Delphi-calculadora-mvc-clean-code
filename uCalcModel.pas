unit uCalcModel;

{
  ---------------------------------------------------------------------------
  UNIDADE: uCalcModel (camada MODEL do padrão MVC)

  O que é uma "unit" em Delphi?
  - Um arquivo Pascal que agrupa tipos, constantes, variáveis e rotinas.
  - A seção "interface" declara o que outros arquivos podem usar.
  - A seção "implementation" contém o código interno (oculto de quem só usa a unit).

  O que é MODEL neste projeto?
  - Guarda o ESTADO da calculadora (número digitado, acumulador, operação pendente).
  - Executa as REGRAS matemáticas (somar, funções científicas, memória).
  - NÃO desenha botões nem conhece formulários: isso é papel da View/Controller.
  ---------------------------------------------------------------------------
}

interface

uses
  System.SysUtils,
  System.Math;

type
  {
    TCalcAngleMode
    - Enumeração: lista fixa de valores possíveis.
    - Aqui define se funções trigonométricas interpretam o número como graus ou radianos.
  }
  TCalcAngleMode = (camDegrees, camRadians);

  {
    TArithmeticOp
    - Representa qual operação binária está "esperando o próximo número".
    - "aoNone" significa que não há operação pendente.
  }
  TArithmeticOp = (aoNone, aoAdd, aoSub, aoMul, aoDiv, aoPow, aoMod);

  {
    TCalcModel
    - Classe: um "molde" que gera objetos em memória.
    - "class" em Delphi define tipos; você cria instâncias com TCalcModel.Create.
  }
  TCalcModel = class
  private
    FAngleMode: TCalcAngleMode;
    FAccumulator: Double;
    FEntry: string;
    FHasEntry: Boolean;
    FMemory: Double;
    FMemoryActive: Boolean;
    FPendingOp: TArithmeticOp;
    FExpressionHint: string;
    FErrorMessage: string;

    function GetEntryAsNumber: Double;
    procedure SetEntryFromNumber(const AValue: Double);
    function ToRadians(const ADegreesOrRadians: Double): Double;
    function FromRadians(const ARadians: Double): Double;
    function FactorialInt(const AN: Integer): Double;
    procedure SetError(const AMsg: string);
    procedure ClearErrorIfAny;
    function TryParseInvariant(const AText: string; out AValue: Double): Boolean;
    function FormatDisplay(const AValue: Double): string;
  public
    constructor Create;

    { --- Entrada de dígitos e separador decimal --- }
    procedure InputDigit(const ADigit: Char);
    procedure InputDecimalSeparator;
    procedure Backspace;
    procedure ToggleSign;
    procedure ClearAll;
    procedure ClearEntry;

    { --- Operações básicas --- }
    procedure PressBinaryOperator(const AOp: TArithmeticOp);
    procedure Equals;

    { --- Memória (M+, M-, MR, MC, MS) --- }
    procedure MemoryClear;
    procedure MemoryRecall;
    procedure MemoryStore;
    procedure MemoryAdd;
    procedure MemorySubtract;

    { --- Modo angular --- }
    procedure SetAngleModeDegrees;
    procedure SetAngleModeRadians;
    function GetAngleMode: TCalcAngleMode;

    { --- Funções científicas (unárias) --- }
    procedure UnarySin;
    procedure UnaryCos;
    procedure UnaryTan;
    procedure UnaryASin;
    procedure UnaryACos;
    procedure UnaryATan;
    procedure UnaryLn;
    procedure UnaryLog10;
    procedure UnarySqrt;
    procedure UnarySquare;
    procedure UnaryInverse;
    procedure UnaryAbs;
    procedure UnaryExp;
    procedure UnaryInt;
    procedure UnaryFrac;
    procedure UnaryFactorial;
    procedure UnaryPercent;

    { --- Constantes --- }
    procedure InsertPi;
    procedure InsertE;

    { --- Operador científico binário x^y (após pressionar, o próximo número é o expoente) --- }
    procedure PressPowerOperator;

    { --- Leitura do estado para a View --- }
    function GetDisplayText: string;
    function GetExpressionHint: string;
    function GetErrorMessage: string;
    function HasError: Boolean;
    function IsMemoryActive: Boolean;
  end;

implementation

{ TCalcModel }

constructor TCalcModel.Create;
begin
  inherited Create;
  { inherited Create chama o construtor da classe ancestral (TObject) para inicialização padrão. }

  FAngleMode := camDegrees;
  FAccumulator := 0;
  FEntry := '0';
  FHasEntry := False;
  FMemory := 0;
  FMemoryActive := False;
  FPendingOp := aoNone;
  FExpressionHint := '';
  FErrorMessage := '';
end;

function TCalcModel.TryParseInvariant(const AText: string; out AValue: Double): Boolean;
var
  LText: string;
begin
  { TryStrToFloat tenta converter texto em número; retorna True se der certo. }
  LText := Trim(AText);
  if LText = '' then
    Exit(False);
  Result := TryStrToFloat(LText, AValue, TFormatSettings.Invariant);
end;

function TCalcModel.GetEntryAsNumber: Double;
begin
  if not TryParseInvariant(FEntry, Result) then
    Result := 0;
end;

procedure TCalcModel.SetEntryFromNumber(const AValue: Double);
begin
  FEntry := FormatDisplay(AValue);
  FHasEntry := True;
end;

function TCalcModel.FormatDisplay(const AValue: Double): string;
begin
  { Formato compacto, invariante, sem depender do separador regional do Windows. }
  Result := FloatToStr(AValue, TFormatSettings.Invariant);
end;

procedure TCalcModel.SetError(const AMsg: string);
begin
  FErrorMessage := AMsg;
  FExpressionHint := '';
end;

procedure TCalcModel.ClearErrorIfAny;
begin
  if FErrorMessage <> '' then
  begin
    FErrorMessage := '';
    ClearAll;
  end;
end;

function TCalcModel.ToRadians(const ADegreesOrRadians: Double): Double;
begin
  { Funções Sin/Cos/Tan do Delphi trabalham em radianos. }
  if FAngleMode = camDegrees then
    Result := DegToRad(ADegreesOrRadians)
  else
    Result := ADegreesOrRadians;
end;

function TCalcModel.FromRadians(const ARadians: Double): Double;
begin
  if FAngleMode = camDegrees then
    Result := RadToDeg(ARadians)
  else
    Result := ARadians;
end;

function TCalcModel.FactorialInt(const AN: Integer): Double;
var
  I: Integer;
begin
  if AN < 0 then
    raise Exception.Create('Fatorial indefinido para negativos.');
  if AN > 170 then
    raise Exception.Create('Fatorial muito grande para exibir com precisão.');

  Result := 1;
  for I := 2 to AN do
    Result := Result * I;
end;

procedure TCalcModel.InputDigit(const ADigit: Char);
begin
  ClearErrorIfAny;

  if not CharInSet(ADigit, ['0'..'9']) then
    Exit;

  if (not FHasEntry) or (FEntry = '0') then
  begin
    FEntry := ADigit;
    FHasEntry := True;
  end
  else
  begin
    { Evita milhões de dígitos sem sentido prático. }
    if Length(FEntry) < 18 then
      FEntry := FEntry + ADigit;
  end;
end;

procedure TCalcModel.InputDecimalSeparator;
begin
  ClearErrorIfAny;

  if not FHasEntry then
  begin
    FEntry := '0.';
    FHasEntry := True;
    Exit;
  end;

  { Pos procura substring; retorna 0 se não existir. }
  if Pos('.', FEntry) = 0 then
    FEntry := FEntry + '.';
end;

procedure TCalcModel.Backspace;
begin
  ClearErrorIfAny;

  if not FHasEntry then
    Exit;

  if Length(FEntry) <= 1 then
    FEntry := '0'
  else
    SetLength(FEntry, Length(FEntry) - 1);
end;

procedure TCalcModel.ToggleSign;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  SetEntryFromNumber(-V);
end;

procedure TCalcModel.ClearAll;
begin
  FAccumulator := 0;
  FPendingOp := aoNone;
  FEntry := '0';
  FHasEntry := False;
  FExpressionHint := '';
  FErrorMessage := '';
end;

procedure TCalcModel.ClearEntry;
begin
  ClearErrorIfAny;
  FEntry := '0';
  FHasEntry := True;
end;

procedure TCalcModel.PressBinaryOperator(const AOp: TArithmeticOp);
var
  Right: Double;
begin
  ClearErrorIfAny;

  if FPendingOp = aoNone then
  begin
    FAccumulator := GetEntryAsNumber;
  end
  else if FHasEntry then
  begin
    Right := GetEntryAsNumber;
    try
      case FPendingOp of
        aoAdd:
          FAccumulator := FAccumulator + Right;
        aoSub:
          FAccumulator := FAccumulator - Right;
        aoMul:
          FAccumulator := FAccumulator * Right;
        aoDiv:
          if Right = 0 then
            raise EDivByZero.Create('Divisão por zero.')
          else
            FAccumulator := FAccumulator / Right;
        aoPow:
          FAccumulator := Power(FAccumulator, Right);
        aoMod:
          if Right = 0 then
            raise EDivByZero.Create('Divisão por zero (resto).')
          else
            FAccumulator := FAccumulator - Int(FAccumulator / Right) * Right;
        aoNone:
          ;
      end;
    except
      on E: Exception do
      begin
        SetError(E.Message);
        Exit;
      end;
    end;
  end;

  FPendingOp := AOp;
  FHasEntry := False;

  case AOp of
    aoAdd:
      FExpressionHint := FormatDisplay(FAccumulator) + ' +';
    aoSub:
      FExpressionHint := FormatDisplay(FAccumulator) + ' -';
    aoMul:
      FExpressionHint := FormatDisplay(FAccumulator) + ' *';
    aoDiv:
      FExpressionHint := FormatDisplay(FAccumulator) + ' /';
    aoPow:
      FExpressionHint := FormatDisplay(FAccumulator) + ' ^';
    aoMod:
      FExpressionHint := FormatDisplay(FAccumulator) + ' mod';
    aoNone:
      FExpressionHint := '';
  end;
end;

procedure TCalcModel.PressPowerOperator;
begin
  PressBinaryOperator(aoPow);
end;

procedure TCalcModel.Equals;
var
  Right: Double;
begin
  ClearErrorIfAny;

  if FPendingOp = aoNone then
  begin
    { Sem operação pendente: apenas "confirma" o número atual. }
    FExpressionHint := '';
    Exit;
  end;

  Right := GetEntryAsNumber;
  try
    case FPendingOp of
      aoAdd:
        FAccumulator := FAccumulator + Right;
      aoSub:
        FAccumulator := FAccumulator - Right;
      aoMul:
        FAccumulator := FAccumulator * Right;
      aoDiv:
        if Right = 0 then
          raise EDivByZero.Create('Divisão por zero.')
        else
          FAccumulator := FAccumulator / Right;
      aoPow:
        FAccumulator := Power(FAccumulator, Right);
      aoMod:
        if Right = 0 then
          raise EDivByZero.Create('Divisão por zero (resto).')
        else
          FAccumulator := FAccumulator - Int(FAccumulator / Right) * Right;
      aoNone:
        ;
    end;
  except
    on E: Exception do
    begin
      SetError(E.Message);
      Exit;
    end;
  end;

  SetEntryFromNumber(FAccumulator);
  FPendingOp := aoNone;
  FExpressionHint := '';
end;

procedure TCalcModel.MemoryClear;
begin
  ClearErrorIfAny;
  FMemory := 0;
  FMemoryActive := False;
end;

procedure TCalcModel.MemoryRecall;
begin
  ClearErrorIfAny;
  SetEntryFromNumber(FMemory);
end;

procedure TCalcModel.MemoryStore;
begin
  ClearErrorIfAny;
  FMemory := GetEntryAsNumber;
  FMemoryActive := True;
end;

procedure TCalcModel.MemoryAdd;
begin
  ClearErrorIfAny;
  FMemory := FMemory + GetEntryAsNumber;
  FMemoryActive := True;
end;

procedure TCalcModel.MemorySubtract;
begin
  ClearErrorIfAny;
  FMemory := FMemory - GetEntryAsNumber;
  FMemoryActive := True;
end;

procedure TCalcModel.SetAngleModeDegrees;
begin
  FAngleMode := camDegrees;
end;

procedure TCalcModel.SetAngleModeRadians;
begin
  FAngleMode := camRadians;
end;

function TCalcModel.GetAngleMode: TCalcAngleMode;
begin
  Result := FAngleMode;
end;

procedure TCalcModel.UnarySin;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  SetEntryFromNumber(Sin(ToRadians(V)));
end;

procedure TCalcModel.UnaryCos;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  SetEntryFromNumber(Cos(ToRadians(V)));
end;

procedure TCalcModel.UnaryTan;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  try
    SetEntryFromNumber(Tan(ToRadians(V)));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

procedure TCalcModel.UnaryASin;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  try
    SetEntryFromNumber(FromRadians(ArcSin(V)));
  except
    on E: Exception do
      SetError('Domínio inválido para arcoseno.');
  end;
end;

procedure TCalcModel.UnaryACos;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  try
    SetEntryFromNumber(FromRadians(ArcCos(V)));
  except
    on E: Exception do
      SetError('Domínio inválido para arcocoseno.');
  end;
end;

procedure TCalcModel.UnaryATan;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  SetEntryFromNumber(FromRadians(ArcTan(V)));
end;

procedure TCalcModel.UnaryLn;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  try
    if V <= 0 then
      raise Exception.Create('ln(x) exige x > 0.');
    SetEntryFromNumber(Ln(V));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

procedure TCalcModel.UnaryLog10;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  try
    if V <= 0 then
      raise Exception.Create('log(x) exige x > 0.');
    SetEntryFromNumber(Ln(V) / Ln(10));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

procedure TCalcModel.UnarySqrt;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  try
    if V < 0 then
      raise Exception.Create('Raiz real exige x >= 0.');
    SetEntryFromNumber(Sqrt(V));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

procedure TCalcModel.UnarySquare;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  SetEntryFromNumber(V * V);
end;

procedure TCalcModel.UnaryInverse;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  try
    if V = 0 then
      raise EDivByZero.Create('Divisão por zero.');
    SetEntryFromNumber(1 / V);
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

procedure TCalcModel.UnaryAbs;
begin
  ClearErrorIfAny;
  SetEntryFromNumber(Abs(GetEntryAsNumber));
end;

procedure TCalcModel.UnaryExp;
begin
  ClearErrorIfAny;
  try
    SetEntryFromNumber(Exp(GetEntryAsNumber));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

procedure TCalcModel.UnaryInt;
begin
  ClearErrorIfAny;
  SetEntryFromNumber(Int(GetEntryAsNumber));
end;

procedure TCalcModel.UnaryFrac;
begin
  ClearErrorIfAny;
  SetEntryFromNumber(Frac(GetEntryAsNumber));
end;

procedure TCalcModel.UnaryFactorial;
var
  V: Double;
  N: Integer;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  N := Trunc(V);
  try
    if Abs(V - N) > 1E-12 then
      raise Exception.Create('Use n inteiro para n!.');
    SetEntryFromNumber(FactorialInt(N));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

procedure TCalcModel.UnaryPercent;
var
  V: Double;
begin
  ClearErrorIfAny;
  V := GetEntryAsNumber;
  SetEntryFromNumber(V / 100);
end;

procedure TCalcModel.InsertPi;
begin
  ClearErrorIfAny;
  SetEntryFromNumber(Pi);
end;

procedure TCalcModel.InsertE;
begin
  ClearErrorIfAny;
  { e = exp(1). A função Exp está na unit System, não em System.Math. }
  SetEntryFromNumber(Exp(1));
end;

function TCalcModel.GetDisplayText: string;
begin
  if FErrorMessage <> '' then
    Exit(FErrorMessage);
  Result := FEntry;
end;

function TCalcModel.GetExpressionHint: string;
begin
  Result := FExpressionHint;
end;

function TCalcModel.GetErrorMessage: string;
begin
  Result := FErrorMessage;
end;

function TCalcModel.HasError: Boolean;
begin
  Result := FErrorMessage <> '';
end;

function TCalcModel.IsMemoryActive: Boolean;
begin
  Result := FMemoryActive;
end;

end.
