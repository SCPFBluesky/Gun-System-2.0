--[[
   @Author: WATDAHECKLOL32
   @Date:   4/5/2025
   @Context: Client
]]
--!nonstrict
--!native
--!optimize 2

-- Fastest gun system of all time ??? maybe??

local FirearmClass = {};
FirearmClass.__index = FirearmClass;

local Players = game:GetService("Players");
local Player = Players.LocalPlayer;

local require: (Instance | number | string) -> any = require;
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local Packet = require(ReplicatedStorage.Packet);
local Init = Packet("InitGun", Packet.Instance);

local UserinputService = game:GetService("UserInputService");
local Mouse = Player:GetMouse();

local Wait: (number?) -> number = task.wait;

local AnimationSpeed: number = 0.2;
local FiringRaycast: RaycastParams = RaycastParams.new();

FiringRaycast.FilterType = Enum.RaycastFilterType.Exclude;
local Main = ReplicatedStorage.Main;

local Muzzle = Main.Muzzle;
local Hit = Main.Effects;

local Delay: <A..., R...>(number?, ((A...) -> (R...)) | thread, A...) -> thread = task.delay;
local Terrain: Terrain? = workspace.Terrain;

local Remote = Packet("Fire", Packet.Instance, {Tool = Packet.Instance, Settings = {Class = Packet.String, Stats = {Range = Packet.NumberS8, Damage = Packet.NumberS8, Ammo = Packet.NumberS8, Automatic = Packet.Boolean8, Delay = Packet.NumberS8}}}, Packet.Any, Packet.Any);
local ClientRemote = Packet("HitEffects", Packet.Instance, Packet.Any, Packet.Any, Packet.NumberS8)

local DeSync: () -> () = task.desynchronize;
local Sync: () -> () = task.synchronize;

local Actor: Actor = script:GetActor();
local Wrap: <A..., R...>((A...) -> (R...)) -> (A...) -> (R...) = coroutine.wrap;

local game, workspace = game, workspace;
local clock = os.clock;

local debug = debug;
local IsA = game.IsA;

local function Effects(Gun: any, HitObject: Instance, HitPos: Vector3, FireSound: number) : ()
	assert(Gun);
	
	Sync();
	
	--debug.profilebegin("Sys effects");
	
	local New: Sound = Instance.new("Sound");
	New.Name = "Discharge";

	New.SoundId = "rbxassetid://"..FireSound;	
	New.Parent = Gun.Handle;

	New:Play();
	
	local Attachment = Hit.Effects:Clone();
	Attachment.Parent = Terrain;
	
	
	if (HitObject and HitPos) then
		Attachment.CFrame = Attachment.CFrame:ToObjectSpace(CFrame.new(HitPos, Gun.Handle.Muzzle.WorldPosition));
		if (HitObject and HitObject.Parent and HitObject.Parent:FindFirstChildWhichIsA("Humanoid")) then
			Attachment.Blood:Emit(10);
			Attachment.Hit:Play();
		else
			Attachment.Flash:Emit(10);
			Attachment.Smoke:Emit(10);
		end;
	end;
	
	
	for _,Effect: ParticleEmitter | PointLight in Muzzle:GetChildren() do
		local Time;
		local NewEffect = Effect:Clone();
		
		NewEffect.Parent = Gun.Handle.Muzzle;

		if NewEffect:IsA("ParticleEmitter") then
			Time = NewEffect.Lifetime.Max;
			NewEffect:Emit(20);
		elseif NewEffect:IsA("PointLight") then
			Time = 0.1;
			NewEffect.Enabled = true;
		end;
		
		Delay(Time, function()
			NewEffect:Destroy();
		end);
	end;
	
	Delay(0.6, function()
		Attachment:Destroy();	
	end);
	
	--debug.profileend()
	
	New.Ended:Wait();
	New:Destroy();
end;

local function CreateAnimation(Name: string, ID: number) : AnimationTrack?
	if not (Player or Player.Character or Player.Character:FindFirstChild("Humanoid")) then
		return nil;
	end;
	

	local Animator: Animator = Player.Character:WaitForChild("Humanoid").Animator;
	local New: Animation = Instance.new("Animation");
	
	New.Name = Name;
	New.AnimationId = "rbxassetid://"..ID;
	local Loaded: AnimationTrack = Animator:LoadAnimation(New);	
	
	return Loaded;
end;

@checked function FirearmClass.Register(Tool: Tool?) : any?
	assert(Tool);		
	local Self = setmetatable({}, FirearmClass);
	Self.Tool = Tool;
	

	local Settings = require(Tool:WaitForChild("Settings"));
	Self.Settings = Settings;
	Self.Ammo = Self.Settings.Stats.Ammo;
	
	Self.Animations = {};
	for Index, Value in Self.Settings.Animations do
		local Actual = CreateAnimation(Index, Value);	
		Self.Animations[Index] = Actual;
	end;
	
	Init:Fire(Tool);
	Self.Equipped = false;
	
	Self.Holstered = false;
	Self.Down = false;
	
	Self.Automatic = Self.Settings.Stats.Automatic or false;
	Self.Range = Self.Settings.Stats.Range or 1000;
	
	Self.CanHolster = Self.Settings.Stats.CanHolster or true;
	Self.Reloading = false;
	
	Self.Shooting = false;
	
	Tool.Activated:Connect(function()
		Self.Down = true;
		Self:Fire()
	end);
	
	Tool.Deactivated:Connect(function()
		Self.Down = false;
		Self:Fire()
	end);
	
	FiringRaycast.FilterDescendantsInstances = {Player.Character, workspace.CurrentCamera};
	return Self;	
end;

function FirearmClass:StopAllAnimations()
	assert(self, "Expected : not . when calling member function StopAllAnimations of FirearmClass");
	
	if not (self or self.Animations) then
		return;
	end;
	
	for _,Animation: AnimationTrack? in self.Animations do
		if Animation then
			Animation:Stop();
		end;
	end;
end;

function FirearmClass:Equip()
	assert(self, "Expected : not . when calling member function Equip of FirearmClass");
	
	if (self.Tool and self.Animations.Idle and Player.Character and self.Tool.Parent == Player.Character) then
		self:StopAllAnimations();
		
		self.Animations.Idle:Play(AnimationSpeed);
		self.Equipped = true;
		
		self.Shooting = false;
	end;
end;

function FirearmClass:Unequip() : ()
	assert(self, "Expected : not . when calling member function Unequip of FirearmClass");
	
	if (self.Tool and self.Animations and Player.Character and self.Tool.Parent ~= Player.Character) then
		self:StopAllAnimations();
		self.Equipped = false;
		
		self.Holstered = false;
		self.Reloading = false;
		
		self.Down = false;
		self.Shooting = false;
	end;
end;

function FirearmClass:Holster() : ()
	assert(self, "Expected : not . when calling member function Holster of FirearmClass");
	
	if (Player and Player.Character and self.Animations.Holster and self.Equipped and self.CanHolster and not self.Reloading) then
		self.Holstered = not self.Holstered;
		if self.Holstered then
			self:StopAllAnimations();
			self.Animations.Holster:Play(AnimationSpeed);
		else
			self.Animations.Holster:Stop();
			self.Animations.Idle:Play(AnimationSpeed);
		end;
	end;
end;

function FirearmClass:Reload() : ()
	assert(self, "Expected : not . when calling member function Reload of FirearmClass");
	
	if (self.Holstered or self.Reloading or self.Ammo == self.Settings.Stats.Ammo or not self.Equipped) then
		return;
	end;
	
	self.Reloading = true;
	self.Animations.Reload:Play(AnimationSpeed);
	
	self.Animations.Reload.Ended:Wait();	
	
	if self.Equipped then
		self.Ammo = self.Settings.Stats.Ammo;		
		self.Reloading = false;
	end;
end;

function FirearmClass:Shoot()
	DeSync();
	--local start = clock();
	
	while (self.Down and self.Tool and self.Equipped and Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.Health > 0 and self.Ammo > 0 and not self.Holstered and not self.Reloading and not self.Shooting) do
		self.Ammo -= 1;
		self.Shooting = true;

		local MouseRay = Mouse.UnitRay;
		local MouseOrigin = MouseRay.Origin;
		local MouseDirection = MouseRay.Direction;

		local MouseHit: RaycastResult = workspace:Raycast(MouseOrigin, MouseDirection * self.Range, FiringRaycast);
		local MousePos: Vector3?;

		if (MouseHit) then
			MousePos = MouseHit.Position;
		end;

		local TargetPosition: Vector3 = MousePos or (MouseOrigin + MouseDirection * self.Range);
		local RayOrigin: Vector3 = Player.Character.Head.Position;

		local DirectionToTarget: Vector3 = (TargetPosition - RayOrigin).Unit;
		local FinalResult = workspace:Raycast(RayOrigin, DirectionToTarget * self.Range, FiringRaycast);

		local HitInstance;
		local Pos;

		if (FinalResult and FinalResult.Instance and FinalResult.Position) then
			HitInstance = FinalResult.Instance;
			Pos = FinalResult.Position;
		else
			HitInstance = nil;
			Pos = nil;
		end;
		
		Wrap(function()
			Effects(self.Tool, HitInstance, Pos, self.Settings.Sounds.Fire);
		end)();

		
		Remote:Fire(self.Tool, self, HitInstance, Pos);
		if not self.Automatic then
			break;
		end;

		Wait(self.Settings.Stats.Delay);
		self.Shooting = false;
	end;
	
	-- local finish = clock() - start
	-- print("Finish shooting", finish); -->  20:44:41.941  Finish shooting 4.999992597731762e-07  -  Client - FirearmClass:293
	
	self.Down = false;
	self.Shooting = false;
end;

function FirearmClass:Fire() : ()
	assert(self, "Expected : not . when calling member function Fire of FirearmClass");
	
	
	if (self.Holstered or self.Reloading or self.Ammo <= 0) then
		return;
	end;
		
	Wrap(function()
		self:Shoot();	
	end)();
end;


ClientRemote.OnClientEvent:Connect(Effects)
return FirearmClass
