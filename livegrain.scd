////////////////////////////////////////////////////////////
// livegrain.scd                                           //
// Boot this file inside SuperCollider to get a hands-on   //
// live granular workstation with a single script.         //
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// 0.  SAFETY & SETUP                                      //
////////////////////////////////////////////////////////////

// Evaluate this whole section first. The SynthDef and the
// control buses must exist before you try to play anything.
(
Server.default = s = Server.local;
s.waitForBoot {
    s.meter;    // optional but handy while performing
    s.freqscope; // also optional
};
)

////////////////////////////////////////////////////////////
// 1.  SHARED STATE                                        //
////////////////////////////////////////////////////////////

(
~clock = TempoClock.new(1.0).permanent_(true);
~bus   = Bus.audio(s, 2);
~fxBus = Bus.audio(s, 2);
~buf   = Buffer.readDialog(s, "Choose an audio file for the grains");
)

////////////////////////////////////////////////////////////
// 2.  THE GRAINER                                         //
////////////////////////////////////////////////////////////

(
SynthDef(\livegrain, { |out=0, fx=0, buf=0, gate=1,
    dens=12, pos=0.5, posVar=0.2, rate=1, rateVar=0.2,
    gDur=0.08, gDurVar=0.04, atk=0.05, rel=0.4,
    panWidth=0.75, pitchJitter=0.05, amp=0.2|
    var env  = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction:2);
    var trig = Dust.kr(dens); // grain density
    var dur  = max(0.002, gDur + TRand.kr(-gDurVar, gDurVar, trig));
    var startPos = pos + TRand.kr(-posVar, posVar, trig);
    startPos = startPos.clip(0, 1);
    var localRate = rate * (1 + TRand.kr(-rateVar, rateVar, trig));
    localRate = localRate * (1 + LFNoise1.kr(3, pitchJitter));
    var sig = TGrains.ar(2, trig, buf, localRate, startPos * BufDur.kr(buf), dur);
    sig = Splay.ar(sig, spread: panWidth, levelComp: false);
    Out.ar(out, sig * amp * env);
    Out.ar(fx, sig * amp * 0.5);
}).add;
)

////////////////////////////////////////////////////////////
// 3.  WET FX BUS                                          //
////////////////////////////////////////////////////////////

(
SynthDef(\grainFX, { |inBus=0, out=0, mix=0.35, room=0.7, damp=0.3|
    var sig = In.ar(inBus, 2);
    sig = FreeVerb2.ar(sig[0], sig[1], mix, room, damp);
    Out.ar(out, sig);
}).add;
)

////////////////////////////////////////////////////////////
// 4.  PROXIES FOR LIVE CONTROL                            //
////////////////////////////////////////////////////////////

(
Ndef.clear;
Ndef(\grain).fadeTime = 4;
Ndef(\grain, { Out.ar(~bus, Silent.ar(2)) }); // placeholder
)

(
Ndef(\grain, {
    var gate = Lag.kr(\gate.kr(1), 0.05);
    var dens = Lag.kr(\dens.kr(18), 0.3);
    var pos  = Lag.kr(\pos.kr(0.5), 0.2);
    var posVar = Lag.kr(\posVar.kr(0.15), 0.2);
    var rate = Lag.kr(\rate.kr(1), 0.2);
    var rateVar = Lag.kr(\rateVar.kr(0.2), 0.2);
    var gDur = Lag.kr(\gDur.kr(0.07), 0.1);
    var gDurVar = Lag.kr(\gDurVar.kr(0.04), 0.1);
    var panWidth = Lag.kr(\panWidth.kr(0.6), 0.2);
    var pitchJitter = Lag.kr(\pitchJitter.kr(0.03), 0.2);
    var amp = Lag.kr(\amp.kr(0.2), 0.2);
    var synth = Synth.tail(s, \livegrain, [
        \out, ~bus,
        \fx, ~fxBus,
        \buf, ~buf,
        \gate, gate,
        \dens, dens,
        \pos, pos,
        \posVar, posVar,
        \rate, rate,
        \rateVar, rateVar,
        \gDur, gDur,
        \gDurVar, gDurVar,
        \panWidth, panWidth,
        \pitchJitter, pitchJitter,
        \amp, amp
    ]);
    synth; // keep reference for freeing
});
)

(
Ndef(\fx).fadeTime = 2;
Ndef(\fx, { Synth.tail(s, \grainFX, [\inBus, ~fxBus, \out, 0]) });
)

////////////////////////////////////////////////////////////
// 5.  LIVE CONTROL HELPER FUNCTIONS                       //
////////////////////////////////////////////////////////////

// Simple helper for setting values with automatic range checking.
(
~set = { |param, value, min=0, max=1|
    value = value.clip(min, max);
    Ndef(\grain).set(param, value);
    ("% set to %".format(param, value)).postln;
};
)

// Example macro gestures for performance
(
~gestures = (
    freeze: {
        ~set.(\dens, 4, 0, 40);
        ~set.(\gDur, 0.15, 0.01, 0.4);
        ~set.(\posVar, 0.02, 0, 0.5);
    },
    spray: {
        ~set.(\dens, 40, 0, 80);
        ~set.(\posVar, 0.4, 0, 0.6);
        ~set.(\rateVar, 0.6, 0, 1);
    },
    reverse: {
        ~set.(\rate, -0.7, -2, 2);
        ~set.(\posVar, 0.15, 0, 0.6);
    }
);
)

////////////////////////////////////////////////////////////
// 6.  CLOCKED POSITION MOD (OPTIONAL)                     //
////////////////////////////////////////////////////////////

// A Pdef that keeps nudging the grain position forward/backward to add motion.
(
Pdef(\posLFO, Pbind(
    \type, \set, \id, Ndef(\grain),
    \args, #[pos],
    \dur, Pwhite(1, 4, inf) / ~clock.tempo,
    \pos, Pfunc { (Ndef(\grain).get(\pos) ? 0.5) + rrand(-0.05, 0.05) }.clip(0.05, 0.95)
)).play(~clock);
)

////////////////////////////////////////////////////////////
// 7.  QUICKSTART CHEATSHEET                               //
////////////////////////////////////////////////////////////
// Evaluate these snippets live to shape the texture:
//
// ~set.(\dens, 25, 1, 60);
// ~set.(\pos, 0.7, 0, 1);
// ~set.(\posVar, 0.25, 0, 0.6);
// ~set.(\rate, 0.5, -4, 4);
// ~set.(\gDur, 0.12, 0.01, 0.5);
// ~set.(\amp, 0.3, 0, 1);
//
// ~gestures.freeze.();
// ~gestures.spray.();
// ~gestures.reverse.();
//
// To swap samples mid-set:
//   ~buf.free; ~buf = Buffer.readDialog(s);
//
// To stop gracefully:
//   Ndef(\grain).set(\gate, 0);
//   Pdef(\posLFO).stop;
//   Ndef.clear;
