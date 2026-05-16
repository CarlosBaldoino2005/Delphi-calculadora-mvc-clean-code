unit Calculadora;

{
  ---------------------------------------------------------------------------
  UNIDADE: Calculadora (camada VIEW do padrão MVC)

  O que é VIEW?
  - Mostra informação ao utilizador (ecrã, etiquetas, botões).
  - Captura cliques e encaminha para o CONTROLLER (sem regra de negócio pesada).

  O que é TForm?
  - Classe base de uma janela Windows na biblioteca VCL (Visual Component Library).
  - O ficheiro .dfm guarda propriedades visuais; o .pas guarda código.

  O que significa "implements ICalcViewPort"?
  - A classe promete implementar todos os métodos definidos na interface.
  - O Controller chama esses métodos através de ICalcViewPort (sem aceder aos TLabel).
  - Em Delphi, esses métodos têm de estar na secção "public" da classe (ver comentário no tipo).
  ---------------------------------------------------------------------------
  ATALHOS DE TECLADO (KeyPreview = True no formulário)
  - Esc           : limpar tudo (equivalente a C)
  - Enter         : igual (=)
  - Backspace     : apagar último dígito (<-)
  - Delete        : limpar entrada atual (CE)
  - 0-9           : dígitos
  - . ou ,        : separador decimal
  - + - * /       : operações
  - %             : percentagem
  - =             : igual
  - ^             : potência (x^y)
  - Teclado numérico: dígitos, + - * / , tecla decimal
  ---------------------------------------------------------------------------
}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  uCalcController;

type
  {
    TfrmCalculadora
    - Formulário principal da aplicação.
  }
  TfrmCalculadora = class(TForm, ICalcViewPort)
    pnlDisplay: TPanel;
    lblExpression: TLabel;
    lblDisplay: TLabel;
    lblAngleMode: TLabel;
    lblMemory: TLabel;
    pnlKeypad: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    FController: TCalcController;
    FKeypadBuilt: Boolean;
    {
      FCommandMap
      - TDictionary<chave, valor>: estrutura genérica que associa texto (comando do botão)
        a uma rotina sem parâmetros (TProc = "reference to procedure").
      - Evita uma longa cadeia if/else na DispatchCommand.
    }
    FCommandMap: TDictionary<string, TProc>;

    procedure ApplyTheme;
    procedure EnsureKeypadBuilt;
    procedure BuildKeypad;
    procedure OnCalcButton(Sender: TObject);
    procedure DispatchCommand(const ACmd: string);
    procedure InitCommandMap;
    procedure RegisterCommand(const ACmd: string; const AAction: TProc);
  public
    {
      ICalcViewPort — estes métodos têm de estar em "public" (regra do Delphi):
      métodos que implementam interface não podem ficar em "private", senão o
      compilador gera o mapa da interface incorretamente e ocorre Access Violation
      quando o Controller chama FView.SetMainDisplay, etc.
    }
    procedure SetMainDisplay(const AText: string);
    procedure SetExpressionLine(const AText: string);
    procedure SetAngleModeBadge(const AText: string);
    procedure SetMemoryBadge(const AVisible: Boolean);
  end;

var
  frmCalculadora: TfrmCalculadora;

implementation

{$R *.dfm}

type
  {
    TKeyDef
    - Pequeno registo (struct) com definição de cada botão.
    - "record" em Delphi agrupa campos sem herança (tipo valor na stack quando local).
  }
  TKeyDef = record
    Row: Integer;
    Col: Integer;
    ColSpan: Integer;
    Caption: string;
    Command: string;
  end;

const
  {
    Constantes de layout (pixels).
    - Evita "números mágicos" espalhados pelo código (boa prática legível).
  }
  CELL_W = 86;
  CELL_H = 42;
  GAP = 8;
  ORIGIN_X = 10;
  ORIGIN_Y = 10;

  {
    KEYMAP
    - Lista estática de botões: posição na grelha + legenda + comando interno.
    - O comando interno é interpretado em DispatchCommand.
  }
  KEYMAP: array [0 .. 47] of TKeyDef = (
    (Row: 0; Col: 0; ColSpan: 1; Caption: 'sin'; Command: 'SIN'),
    (Row: 0; Col: 1; ColSpan: 1; Caption: 'cos'; Command: 'COS'),
    (Row: 0; Col: 2; ColSpan: 1; Caption: 'tan'; Command: 'TAN'),
    (Row: 0; Col: 3; ColSpan: 1; Caption: 'ln'; Command: 'LN'),
    (Row: 0; Col: 4; ColSpan: 1; Caption: 'log'; Command: 'LOG'),

    (Row: 1; Col: 0; ColSpan: 1; Caption: 'asin'; Command: 'ASIN'),
    (Row: 1; Col: 1; ColSpan: 1; Caption: 'acos'; Command: 'ACOS'),
    (Row: 1; Col: 2; ColSpan: 1; Caption: 'atan'; Command: 'ATAN'),
    (Row: 1; Col: 3; ColSpan: 1; Caption: 'x^y'; Command: 'POW'),
    (Row: 1; Col: 4; ColSpan: 1; Caption: 'sqrt'; Command: 'SQRT'),

    (Row: 2; Col: 0; ColSpan: 1; Caption: 'x^2'; Command: 'SQR'),
    (Row: 2; Col: 1; ColSpan: 1; Caption: '1/x'; Command: 'INV'),
    (Row: 2; Col: 2; ColSpan: 1; Caption: 'n!'; Command: 'FAC'),
    (Row: 2; Col: 3; ColSpan: 1; Caption: 'Int'; Command: 'INT'),
    (Row: 2; Col: 4; ColSpan: 1; Caption: 'Frac'; Command: 'FRAC'),

    (Row: 3; Col: 0; ColSpan: 1; Caption: 'pi'; Command: 'PI'),
    (Row: 3; Col: 1; ColSpan: 1; Caption: 'e'; Command: 'EE'),
    (Row: 3; Col: 2; ColSpan: 1; Caption: 'Exp'; Command: 'EXP'),
    (Row: 3; Col: 3; ColSpan: 1; Caption: '|x|'; Command: 'ABS'),
    (Row: 3; Col: 4; ColSpan: 1; Caption: '%'; Command: 'PCT'),

    (Row: 4; Col: 0; ColSpan: 1; Caption: 'Deg'; Command: 'DEG'),
    (Row: 4; Col: 1; ColSpan: 1; Caption: 'Rad'; Command: 'RAD'),
    (Row: 4; Col: 2; ColSpan: 1; Caption: 'MC'; Command: 'MEMC'),
    (Row: 4; Col: 3; ColSpan: 1; Caption: 'MR'; Command: 'MEMR'),
    (Row: 4; Col: 4; ColSpan: 1; Caption: 'MS'; Command: 'MEMS'),

    (Row: 5; Col: 0; ColSpan: 1; Caption: 'M+'; Command: 'MEMA'),
    (Row: 5; Col: 1; ColSpan: 1; Caption: 'M-'; Command: 'MEMK'),
    (Row: 5; Col: 2; ColSpan: 1; Caption: 'C'; Command: 'CA'),
    (Row: 5; Col: 3; ColSpan: 1; Caption: 'CE'; Command: 'CE'),
    (Row: 5; Col: 4; ColSpan: 1; Caption: '<-'; Command: 'BS'),

    (Row: 6; Col: 0; ColSpan: 1; Caption: '7'; Command: 'D7'),
    (Row: 6; Col: 1; ColSpan: 1; Caption: '8'; Command: 'D8'),
    (Row: 6; Col: 2; ColSpan: 1; Caption: '9'; Command: 'D9'),
    (Row: 6; Col: 3; ColSpan: 1; Caption: '/'; Command: 'DIV'),
    (Row: 6; Col: 4; ColSpan: 1; Caption: 'mod'; Command: 'MOD'),

    (Row: 7; Col: 0; ColSpan: 1; Caption: '4'; Command: 'D4'),
    (Row: 7; Col: 1; ColSpan: 1; Caption: '5'; Command: 'D5'),
    (Row: 7; Col: 2; ColSpan: 1; Caption: '6'; Command: 'D6'),
    (Row: 7; Col: 3; ColSpan: 1; Caption: '*'; Command: 'MUL'),
    (Row: 7; Col: 4; ColSpan: 1; Caption: '+/-'; Command: 'SIGN'),

    (Row: 8; Col: 0; ColSpan: 1; Caption: '1'; Command: 'D1'),
    (Row: 8; Col: 1; ColSpan: 1; Caption: '2'; Command: 'D2'),
    (Row: 8; Col: 2; ColSpan: 1; Caption: '3'; Command: 'D3'),
    (Row: 8; Col: 3; ColSpan: 1; Caption: '-'; Command: 'SUB'),
    (Row: 8; Col: 4; ColSpan: 1; Caption: '='; Command: 'EQ'),

    (Row: 9; Col: 0; ColSpan: 2; Caption: '0'; Command: 'D0'),
    (Row: 9; Col: 2; ColSpan: 1; Caption: ','; Command: 'DEC'),
    (Row: 9; Col: 3; ColSpan: 1; Caption: '+'; Command: 'ADD')
  );

procedure TfrmCalculadora.FormCreate(Sender: TObject);
begin
  {
    FormCreate
    - Evento disparado depois do formulário e componentes do .dfm existirem.
    - Aqui ligamos o Controller passando Self (este form implementa ICalcViewPort).
  }
  FController := TCalcController.Create(Self);
  FKeypadBuilt := False;
  InitCommandMap;
  { KeyPreview: o formulário recebe teclas antes do controlo focado (ex.: botão). }
  KeyPreview := True;
  ApplyTheme;
  {
    BuildKeypad NÃO fica aqui: com painéis em Align, no FormCreate o pnlKeypad
    ainda pode ter ClientHeight = 0; os botões ficariam todos recortados (invisíveis).
    Construímos o teclado no FormShow, depois do layout final.
  }
end;

procedure TfrmCalculadora.FormDestroy(Sender: TObject);
begin
  {
    FormDestroy
    - Liberta o mapa de comandos e o Controller (que por sua vez liberta o Model).
  }
  FCommandMap.Free;
  FController.Free;
end;

procedure TfrmCalculadora.FormShow(Sender: TObject);
begin
  {
    FormShow
    - Disparado quando a janela vai ser exibida; nesta altura os controlos com Align
      já têm dimensões reais (área útil do pnlKeypad > 0).
  }
  EnsureKeypadBuilt;
end;

procedure TfrmCalculadora.FormResize(Sender: TObject);
begin
  {
    FormResize
    - Se o primeiro FormShow ocorrer antes do layout final (altura ainda 0),
      o primeiro redimensionamento válido constrói o teclado.
  }
  EnsureKeypadBuilt;
end;

procedure TfrmCalculadora.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  {
    FormKeyDown
    - Com KeyPreview, este evento corre primeiro; Key := 0 "come" a tecla para não
      chegar ao botão (evita bip e duplo processamento).
    - Teclas não imprimíveis e teclado numérico tratamos aqui.
  }
  if not Assigned(FController) then
    Exit;

  if (ssCtrl in Shift) or (ssAlt in Shift) then
    Exit;

  case Key of
    VK_TAB:
      Exit;

    VK_ESCAPE:
      begin
        FController.ActionClearAll;
        Key := 0;
      end;

    VK_RETURN:
      begin
        FController.ActionEquals;
        Key := 0;
      end;

    VK_BACK:
      begin
        FController.ActionBackspace;
        Key := 0;
      end;

    VK_DELETE:
      begin
        FController.ActionClearEntry;
        Key := 0;
      end;

    VK_DECIMAL:
      begin
        FController.ActionDecimal;
        Key := 0;
      end;

    VK_NUMPAD0 .. VK_NUMPAD9:
      begin
        FController.ActionDigit(Char(Ord('0') + (Key - VK_NUMPAD0)));
        Key := 0;
      end;

    VK_ADD:
      begin
        FController.ActionAdd;
        Key := 0;
      end;

    VK_SUBTRACT:
      begin
        FController.ActionSubtract;
        Key := 0;
      end;

    VK_MULTIPLY:
      begin
        FController.ActionMultiply;
        Key := 0;
      end;

    VK_DIVIDE:
      begin
        FController.ActionDivide;
        Key := 0;
      end;

    VK_OEM_PERIOD, VK_OEM_COMMA:
      begin
        FController.ActionDecimal;
        Key := 0;
      end;
  end;
  {
    Nota: não tratamos VK_0..VK_9 da fila principal aqui — com Shift (ex.: * em Shift+8)
    seriam confundidos com dígitos. Os números da fila principal vão em FormKeyPress.
  }
end;

procedure TfrmCalculadora.FormKeyPress(Sender: TObject; var Key: Char);
begin
  {
    FormKeyPress
    - Caracteres imprimíveis (+ - * / etc.) vêm aqui já "traduzidos" pelo layout.
    - Key := #0 impede que o carácter seja processado mais abaixo.
  }
  if not Assigned(FController) then
    Exit;

  if (GetKeyState(VK_CONTROL) < 0) or (GetKeyState(VK_MENU) < 0) then
    Exit;

  case Key of
    '0' .. '9':
      begin
        FController.ActionDigit(Key);
        Key := #0;
      end;

    '.', ',':
      begin
        FController.ActionDecimal;
        Key := #0;
      end;

    '+':
      begin
        FController.ActionAdd;
        Key := #0;
      end;

    '-':
      begin
        FController.ActionSubtract;
        Key := #0;
      end;

    '*':
      begin
        FController.ActionMultiply;
        Key := #0;
      end;

    '/':
      begin
        FController.ActionDivide;
        Key := #0;
      end;

    '%':
      begin
        FController.ActionPercent;
        Key := #0;
      end;

    '=':
      begin
        FController.ActionEquals;
        Key := #0;
      end;

    '^':
      begin
        FController.ActionPower;
        Key := #0;
      end;
  end;
end;

procedure TfrmCalculadora.EnsureKeypadBuilt;
begin
  if FKeypadBuilt then
    Exit;
  pnlKeypad.HandleNeeded;
  if pnlKeypad.ClientHeight < 40 then
    Exit;
  BuildKeypad;
  FKeypadBuilt := True;
end;

procedure TfrmCalculadora.ApplyTheme;
begin
  {
    ApplyTheme
    - Centraliza cores e tipografia para um visual coeso (tema escuro suave).
  }
  Color := $00404040;
  ParentBackground := False;
  Font.Name := 'Segoe UI';
  Font.Size := 10;
  Font.Color := $00F0F0F0;

  pnlDisplay.Color := $00282828;
  pnlDisplay.BevelOuter := bvNone;
  { ParentBackground False evita que o tema desenhe por cima da cor do painel. }
  pnlDisplay.ParentBackground := False;

  lblExpression.Font.Color := $00B0B0B0;
  lblExpression.Font.Size := 11;

  lblDisplay.Font.Size := 22;
  lblDisplay.Font.Style := [];
  lblDisplay.Font.Color := clWhite;

  lblAngleMode.Font.Color := $009ADBC8;
  lblMemory.Font.Color := $009ADBC8;

  pnlKeypad.Color := $00343434;
  pnlKeypad.BevelOuter := bvNone;
  pnlKeypad.ParentBackground := False;
end;

procedure TfrmCalculadora.BuildKeypad;
var
  I: Integer;
  Btn: TButton;
  LLeft, LTop, LWidth: Integer;
begin
  {
    BuildKeypad
    - Cria botões em tempo de execução (Owner = Self => libertação automática ao fechar o form).
    - Parent = pnlKeypad mantém os botões dentro do painel.
  }
  for I := Low(KEYMAP) to High(KEYMAP) do
  begin
    if KEYMAP[I].Command = '' then
      Continue;

    Btn := TButton.Create(Self);
    Btn.Parent := pnlKeypad;
    Btn.Visible := True;
    Btn.Tag := I;
    Btn.Caption := KEYMAP[I].Caption;
    Btn.Hint := KEYMAP[I].Command;
    Btn.ShowHint := False;
    Btn.OnClick := OnCalcButton;

    LLeft := ORIGIN_X + KEYMAP[I].Col * (CELL_W + GAP);
    LTop := ORIGIN_Y + KEYMAP[I].Row * (CELL_H + GAP);
    LWidth := KEYMAP[I].ColSpan * CELL_W + (KEYMAP[I].ColSpan - 1) * GAP;

    Btn.SetBounds(LLeft, LTop, LWidth, CELL_H);
    Btn.Font.Size := 9;

    if (Length(KEYMAP[I].Command) = 2) and (KEYMAP[I].Command[1] = 'D') and
      CharInSet(KEYMAP[I].Command[2], ['0'..'9']) then
      Btn.Font.Style := [fsBold]
    else if (KEYMAP[I].Command = 'EQ') or (KEYMAP[I].Command = 'ADD') or (KEYMAP[I].Command = 'SUB') or
      (KEYMAP[I].Command = 'MUL') or (KEYMAP[I].Command = 'DIV') or (KEYMAP[I].Command = 'MOD') or
      (KEYMAP[I].Command = 'POW') then
    begin
      Btn.Font.Color := clWhite;
      Btn.Font.Style := [fsBold];
    end;
  end;
end;

procedure TfrmCalculadora.OnCalcButton(Sender: TObject);
var
  B: TButton;
  Cmd: string;
  Idx: Integer;
begin
  {
    OnCalcButton
    - Lê o comando do Hint; se estiver vazio (alguns temas/VCL), usa Tag como índice no KEYMAP.
  }
  if not(Sender is TButton) then
    Exit;
  B := TButton(Sender);
  Cmd := Trim(B.Hint);
  if Cmd = '' then
  begin
    Idx := B.Tag;
    if (Idx >= Low(KEYMAP)) and (Idx <= High(KEYMAP)) then
      Cmd := KEYMAP[Idx].Command;
  end;
  DispatchCommand(Cmd);
end;

procedure TfrmCalculadora.RegisterCommand(const ACmd: string; const AAction: TProc);
begin
  {
    RegisterCommand
    - Função auxiliar: uma vez só escrevemos FCommandMap.Add(...).
    - O segundo parâmetro é TProc (reference to procedure), típico para delegates em Delphi.
  }
  FCommandMap.Add(ACmd, AAction);
end;

procedure TfrmCalculadora.InitCommandMap;
begin
  {
    InitCommandMap
    - Preenche o dicionário uma vez: cada tecla lógica (ex.: 'SIN') aponta para
      uma rotina anónima que delega no FController.
  }
  FCommandMap := TDictionary<string, TProc>.Create;
  RegisterCommand('DEC', procedure begin FController.ActionDecimal end);
  RegisterCommand('BS', procedure begin FController.ActionBackspace end);
  RegisterCommand('SIGN', procedure begin FController.ActionToggleSign end);
  RegisterCommand('CA', procedure begin FController.ActionClearAll end);
  RegisterCommand('CE', procedure begin FController.ActionClearEntry end);
  RegisterCommand('ADD', procedure begin FController.ActionAdd end);
  RegisterCommand('SUB', procedure begin FController.ActionSubtract end);
  RegisterCommand('MUL', procedure begin FController.ActionMultiply end);
  RegisterCommand('DIV', procedure begin FController.ActionDivide end);
  RegisterCommand('MOD', procedure begin FController.ActionMod end);
  RegisterCommand('EQ', procedure begin FController.ActionEquals end);
  RegisterCommand('PCT', procedure begin FController.ActionPercent end);
  RegisterCommand('POW', procedure begin FController.ActionPower end);
  RegisterCommand('SIN', procedure begin FController.ActionSin end);
  RegisterCommand('COS', procedure begin FController.ActionCos end);
  RegisterCommand('TAN', procedure begin FController.ActionTan end);
  RegisterCommand('ASIN', procedure begin FController.ActionASin end);
  RegisterCommand('ACOS', procedure begin FController.ActionACos end);
  RegisterCommand('ATAN', procedure begin FController.ActionATan end);
  RegisterCommand('LN', procedure begin FController.ActionLn end);
  RegisterCommand('LOG', procedure begin FController.ActionLog10 end);
  RegisterCommand('SQRT', procedure begin FController.ActionSqrt end);
  RegisterCommand('SQR', procedure begin FController.ActionSquare end);
  RegisterCommand('INV', procedure begin FController.ActionInverse end);
  RegisterCommand('ABS', procedure begin FController.ActionAbs end);
  RegisterCommand('EXP', procedure begin FController.ActionExp end);
  RegisterCommand('INT', procedure begin FController.ActionInt end);
  RegisterCommand('FRAC', procedure begin FController.ActionFrac end);
  RegisterCommand('FAC', procedure begin FController.ActionFactorial end);
  RegisterCommand('PI', procedure begin FController.ActionPi end);
  RegisterCommand('EE', procedure begin FController.ActionE end);
  RegisterCommand('MEMC', procedure begin FController.ActionMemoryClear end);
  RegisterCommand('MEMR', procedure begin FController.ActionMemoryRecall end);
  RegisterCommand('MEMS', procedure begin FController.ActionMemoryStore end);
  RegisterCommand('MEMA', procedure begin FController.ActionMemoryAdd end);
  RegisterCommand('MEMK', procedure begin FController.ActionMemorySubtract end);
  RegisterCommand('DEG', procedure begin FController.ActionAngleDegrees end);
  RegisterCommand('RAD', procedure begin FController.ActionAngleRadians end);
end;

procedure TfrmCalculadora.DispatchCommand(const ACmd: string);
var
  AAction: TProc;
begin
  if not Assigned(FController) then
    Exit;
  {
    DispatchCommand
    - Dígitos D0..D9 mantêm tratamento explícito (padrão curto).
    - Demais comandos: procura O(1) no TDictionary e executa a rotina associada.
  }
  if ACmd = '' then
    Exit;

  if (Length(ACmd) = 2) and (ACmd[1] = 'D') and CharInSet(ACmd[2], ['0'..'9']) then
  begin
    FController.ActionDigit(ACmd[2]);
    Exit;
  end;

  if FCommandMap.TryGetValue(ACmd, AAction) then
    AAction();
end;

procedure TfrmCalculadora.SetMainDisplay(const AText: string);
begin
  lblDisplay.Caption := AText;
end;

procedure TfrmCalculadora.SetExpressionLine(const AText: string);
begin
  lblExpression.Caption := AText;
end;

procedure TfrmCalculadora.SetAngleModeBadge(const AText: string);
begin
  lblAngleMode.Caption := 'Angulo: ' + AText;
end;

procedure TfrmCalculadora.SetMemoryBadge(const AVisible: Boolean);
begin
  if AVisible then
    lblMemory.Caption := 'Memoria: M'
  else
    lblMemory.Caption := 'Memoria: --';
end;

end.
