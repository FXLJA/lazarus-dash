unit utama;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, MPlayerCtrl;

type

  { TForm1 }

  TForm1 = class(TForm)
    Stage1: TImage;

    announceLabel: TLabel;
    scoreLabel: TLabel;
    timerBackground: TTimer;
    Volume: TLabel;

    Stage: TImage;
    btnPlay: TImage;
    btnExit: TImage;
    imgChara: TImage;
    imgFloor: TImage;
    imgFloor1: TImage;
    btnSetting: TImage;
    btnRestart: TImage;
    imgSpike: TImage;
    imgSpike1: TImage;
    imgSpike2: TImage;

    pnlSettings: TPanel;

    timerArena: TTimer;
    timerCharacter: TTimer;

    tbVolume: TTrackBar;

    MPlayerControl1: TMPlayerControl;

    procedure btnExitClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnRestartClick(Sender: TObject);
    procedure btnSettingClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure tbVolumeChange(Sender: TObject);
    procedure timerArenaTimer(Sender: TObject);
    procedure timerBackgroundTimer(Sender: TObject);
    procedure timerCharacterTimer(Sender: TObject);

  private
  type KinematicBody = record
    position :TPoint;
    velocity :TPoint;
    const_force :TPoint;
    last_rotation : double;
    rotation :double;
    angular_vel : double;
    is_on_floor: boolean;
  end;

  var
    player_data: KinematicBody;

  public
    procedure redraw_player(rotasi: double);
    function is_box_collide(box_a:TImage; box_b:TImage):boolean;

  end;

var
  Form1: TForm1;
  x: Integer;
  gerak: Integer;
  moveChara: Boolean;
  score: Integer;
  counter: Integer;

implementation

{$R *.lfm}

{ TForm1 }
//==============================================================================
//                              GAME START
//==============================================================================
procedure TForm1.FormShow(Sender: TObject);
begin
  score := 0;
  counter := 0;

  announceLabel.Hide;

  player_data.position.x := imgChara.left;
  player_data.position.y := imgChara.top;
  player_data.velocity.x := 0;
  player_data.velocity.y := 0;
  player_data.const_force.x := 0;  //Kecepatan geser
  player_data.const_force.y := 10; //Kecepatan jatuh
  player_data.rotation := 0;
  player_data.angular_vel := 0;

  Stage.Canvas.Pen.Color:= clWhite;
  Stage.Canvas.Brush.Color:= clWhite;
  Stage.Canvas.Rectangle(0, 0, Stage.Width, Stage.Height);

  btnPlay.Picture.LoadFromFile('Images\Icon_Play.png');
  btnSetting.Picture.LoadFromFile('Images\Icon_Setting.png');
  btnRestart.Picture.LoadFromFile('Images\Icon_Replay.png');
  btnExit.Picture.LoadFromFile('Images\Icon_Exit.png');

  imgFloor.Picture.LoadFromFile('Images\Floor1.png');
  imgFloor1.Picture.LoadFromFile('Images\Floor2.png');

  imgSpike.Picture.LoadFromFile('Images\spike.png');
  imgSpike1.Picture.LoadFromFile('Images\spike.png');
  imgSpike2.Picture.LoadFromFile('Images\spike.png');

  Stage.Picture.LoadFromFile('Images\bg1.png');
  Stage1.Picture.LoadFromFile('Images\bg2.png');

  imgChara.Transparent:= true;
end;

//==============================================================================


//==============================================================================
//                             PLAY BUTTON
//==============================================================================
procedure TForm1.btnPlayClick(Sender: TObject);
begin
  btnPlay.Visible:= False;
  btnSetting.Visible:= True;

  //Start Timer
  timerArena.Enabled:= not timerArena.Enabled;
  timerCharacter.Enabled:= not timerCharacter.Enabled;
  timerBackground.Enabled:= not timerBackground.Enabled;

  //Play Song
  MPlayerControl1.Filename:= 'Song\astronomia.mp3';
  MPlayerControl1.Volume:= 50;
  MPlayerControl1.Play;

  //Start Animation
  redraw_player(0);
end;
//==============================================================================


//==============================================================================
//                            SETTING BUTTON
//==============================================================================
procedure TForm1.btnSettingClick(Sender: TObject);
begin

  //Panel Color
  pnlSettings.Color:= RGBToColor(136, 0, 103);

  //Pause The Game
  MPlayerControl1.Paused:= True;
  timerArena.Enabled:= not timerArena.Enabled;
  timerCharacter.Enabled:= not timerCharacter.Enabled;
  timerBackground.Enabled:= not timerBackground.Enabled;

  //Show Setting
  pnlSettings.Visible:= True;
  announceLabel.Hide;
  tbVolume.Visible:= True;
  Volume.Visible:= True;
end;
//==============================================================================


//==============================================================================
//                            RESTART BUTTON
//==============================================================================
procedure TForm1.btnRestartClick(Sender: TObject);
begin
  //Reset Score
  score := 0;
  counter := 0;

  //Song Restart
  MPlayerControl1.Stop;
  MPlayerControl1.Volume:= tbVolume.Position;
  MPlayerControl1.Play;

  timerArena.Enabled:= True;
  timerCharacter.Enabled:= True;
  timerBackground.Enabled:= True;

  //Hide Setting
  pnlSettings.Visible:= False;

  //Show btn Exit
  btnExit.Visible:= True;

  imgSpike.Left:= 2000;
  imgSpike1.Left:= 2000;
  imgSpike2.Left:= 2000;

  redraw_player(0);
end;
//==============================================================================


//==============================================================================
//                            VOLUME SETTING
//==============================================================================
procedure TForm1.tbVolumeChange(Sender: TObject);
begin
  MPlayerControl1.Volume:= tbVolume.Position;
end;
//==============================================================================


//==============================================================================
//                           EXIT SETTING BUTTON
//==============================================================================
procedure TForm1.btnExitClick(Sender: TObject);
begin
  //Resume Game
  MPlayerControl1.Paused:= False;
  timerArena.Enabled:= not timerArena.Enabled;
  timerCharacter.Enabled:= not timerCharacter.Enabled;
  timerBackground.Enabled:= not timerBackground.Enabled;

  //Hide Settings
  pnlSettings.Visible:= False;
end;
//==============================================================================

//==============================================================================
//                                ANIMASI UTAMA
//==============================================================================
//Kontrol loncat
procedure TForm1.FormKeyPress(Sender: TObject; var Key: char);
var
  waktu : double;
  step : integer;

begin
  //Loncat: Tekan spasi
  if (key = ' ') and player_data.is_on_floor then
  begin
    //Tinggi loncat
    player_data.velocity.y := -60;

    //Parabola
    waktu := player_data.velocity.y/player_data.const_force.y;
    step := Round((waktu*100/timerArena.Interval))+1;

    //Putar Icon
    player_data.angular_vel:= -180.0/step;
  end;
end;

//Timer Arena & Obstacle
procedure TForm1.timerArenaTimer(Sender: TObject);
begin
  //Score
    counter:= counter + 1;

    if counter mod 10 = 0 then
    begin
      score:= score + 1;
    end;
    scoreLabel.Caption:= IntToStr(score);

  //Floor
  imgFloor.Left := imgFloor.Left - 24;
  imgFloor1.Left := imgFloor1.Left - 24;

  if imgFloor.Left < -1000 then
    imgFloor.Left := 0;

  if imgFloor1.Left < 0 then
    imgFloor1.Left := 1000;

  //Obstacle
  if imgSpike.Left < -60 then
    imgSpike.Left := imgSpike.Left + width +random(2000);
  if imgSpike1.Left < -60 then
    imgSpike1.Left := imgSpike1.Left + width +random(2000);
  if imgSpike2.Left < -60 then
    imgSpike2.Left := imgSpike2.Left + width +random(2000);

  imgSpike.Left := imgSpike.Left - 24;
  imgSpike1.Left := imgSpike1.Left - 24;
  imgSpike2.Left := imgSpike2.Left - 24;
end;

//Timer Background
procedure TForm1.timerBackgroundTimer(Sender: TObject);
begin
  Stage.Left := Stage.Left - 12;
  Stage1.Left := Stage1.Left - 12;

  if Stage.Left < -1000 then
    Stage.Left := 0;

  if Stage1.Left < 0 then
    Stage1.Left := 1000;
end;

//Timer Character
procedure TForm1.timerCharacterTimer(Sender: TObject);
begin
  //Update posisi imgChara
  player_data.last_rotation := player_data.rotation;
  player_data.is_on_floor := false;
  player_data.velocity.x := player_data.velocity.x + player_data.const_force.x;
  player_data.velocity.y := player_data.velocity.y + player_data.const_force.y;
  player_data.position.x := player_data.position.x + player_data.velocity.x;
  player_data.position.y := player_data.position.y + player_data.velocity.y;

  if player_data.position.y > 384 then
  begin
    player_data.position.y := 384;
    player_data.velocity.y := 0;
    player_data.angular_vel:= 0;
    player_data.rotation := Round(player_data.rotation/90)*90;
    player_data.is_on_floor := true;
  end;

  player_data.rotation := player_data.rotation + player_data.angular_vel;

  //Collision
  if (is_box_collide(imgChara, imgSpike)) or
     (is_box_collide(imgChara, imgSpike1)) or
     (is_box_collide(imgChara, imgSpike2)) then
  begin
    btnSettingClick(Sender);
    announceLabel.Visible:= True;
    Volume.Hide;
    tbVolume.Hide;
    btnExit.Visible:= False;

    imgSpike.Left  := Width+random(2000);

    repeat
      imgSpike1.Left := Width+random(2000);
    until abs(imgSpike.Left - imgSpike1.Left) > 120;

   repeat
      imgSpike2.Left := Width+random(2000);
    until abs(imgSpike.Left - imgSpike2.Left) > 120;
  end;

  //Redraw setiap selesai looncat
  imgChara.left := player_data.position.x;
  imgChara.Top  := player_data.position.y;

  if(Round(player_data.last_rotation/30)) <> (Round(player_data.rotation/30)) then
    redraw_player(player_data.rotation);
end;

//==============================================================================

//Redraw
procedure TForm1.redraw_player(rotasi: double);
var
  player: TPicture;
  buffer: TBitmap;
  j: integer;
  k: Integer;
  x: integer;
  y: Integer;

  pivot: TPoint;
  offset: TPoint;
  rad: double;
  r_cos: double;
  r_sin: double;

begin
  player := TPicture.Create;
  buffer := TBitmap.Create;

  buffer.Transparent:=true;
  buffer.TransparentColor:=clWhite;

  try
    player.LoadFromFile('Images/icon.png');

    buffer.Width := player.Width *2;
    buffer.Height:= player.height*2;

    offset.x := player.Width div 2;
    offset.y := player.Width div 2;

    rad := rotasi * PI/180.0;
    r_cos := cos(rad);
    r_sin := sin(rad);

    pivot.x := player.Width  div 2;
    pivot.y := player.Height div 2;

    for j := 0 to buffer.Width do
    begin
      for k := 0 to buffer.Height do
      begin
        buffer.Canvas.pixels[j,k] := clWhite;
      end;
    end;

    for j := 0 to player.Width do
    begin
      for k := 0 to player.Height do
      begin
        x := offset.x + pivot.x + Round(r_cos * (j-pivot.x) - r_sin * (k-pivot.y));
        y := offset.y + pivot.y + Round(r_sin * (j-pivot.x) + r_cos * (k-pivot.y));

        buffer.Canvas.pixels[x,y] := player.Bitmap.Canvas.Pixels[j,k];
      end;
    end;

    imgChara.Picture.Bitmap := buffer;
  finally
    player.Free;
    buffer.Free;
  end;
end;

function TForm1.is_box_collide(box_a: TImage; box_b: TImage):boolean;
var
  player_box: TRect;
  spike: TRect;
begin
  player_box.Left   := box_a.Left + box_a.Width div 4;
  player_box.Top    := box_a.Top + box_a.Height div 4;
  player_box.Right  := box_a.Left + box_a.Width div 2;
  player_box.Bottom := box_a.Top + box_a.Height div 2;

  spike.Left   := box_b.Left;
  spike.Top    := box_b.Top;
  spike.Right  := box_b.Left + box_b.Width;
  spike.Bottom := box_b.Top + box_b.Height;

  is_box_collide := player_box.IntersectsWith(spike);
end;

end.
