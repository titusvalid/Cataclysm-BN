--[[定数]]--


--[[文字のハイライト色パターン]]--
H_COLOR = {
	BLACK		= "black",
	WHITE		= "white",
	LIGHT_GRAY	= "light_gray",
	DARK_GRAY	= "dark_gray",
	RED			= "red",
	GREEN		= "green",
	BLUE		= "blue",
	CYAN		= "cyan",
	MAGENTA		= "magenta",
	BROWN		= "brown",
	LIGHT_RED	= "light_red",
	LIGHT_GREEN	= "light_green",
	LIGHT_BLUE	= "light_blue",
	LIGHT_CYAN	= "light_cyan",
	PINK		= "pink",
	YELLOW		= "yellow"
}

--[[*気持ちいいこと*中に表示されるテキスト]]--
MOVINGDOING_TEXTS = {
    generic = {
        "*Her insides clench around you tightly.* Mmh... that feels good...",
        "*Her breath hitches as you press against her.* Ah... deeper...",
        "*The slick sound of skin slapping skin echoes.* Oh... right there...",
        "*She shifts her hips, trying to take you deeper.* Yes... just like that...",
        "*You feel her wetness coating you with every movement.* More... please...",
        "*A low moan escapes her as you find a rhythm.* Harder... don't stop...",
        "*Her chest rises and falls rapidly against yours.* Faster... I'm getting close...",
        "*Her inner walls pulse around you.* Deeper... hit that spot again...",
        "*She gasps loudly, gripping you tighter.* Don't stop... I need this...",
        "*Her back arches off the surface.* R-right there... fuck...",
        "*Her legs tremble around your waist.* I... it feels so good...",
        "*Her eyes flutter closed as you thrust deeply.* Oh god... you fill me up completely...",
        "*Her fingers dig into your back.* Keep going... I'm almost there...",
        "*Her body convulses as she cries out.* Yes, like that... I'm coming!",
        "*Her warm breath ghosts across your skin.* You feel amazing inside me...",
        "*Her whole body shivers uncontrollably.* I'm so close... please fill me...",
        "*She matches your rhythm, moving against you eagerly.* Like this? Does this feel good?",
        "*She bites down on her lip, muffling a cry.* Mmm... more... harder...",
        "*Her gaze meets yours, intense and wanting.* I want all of you inside me..."
    },
    nonconsent_generic = { -- New table for non-consensual generic fallback
        "*Her body fights yours, muscles straining against your hold.* Get off me!",
        "*She thrashes beneath you, trying to throw you off.* I'll kill you for this!",
        "*Her breath comes in harsh gasps as you force her legs wider.* Stop! Please!",
        "*She claws at your back, leaving stinging trails.* You bastard!",
        "*Her teeth grit as you slam into her.* I hate you!",
        "*She tries to buck you off, her hips slamming against yours.* Let go!",
        "*Her fists beat against your chest futilely.* No! Get away!",
        "*She twists her head, spitting curses at you.* You won't get away with this!",
        "*Her nails dig into your shoulders as you pin her down.* I'll make you pay!",
        "*Her legs lock around you, trying to squeeze the breath out.* Die!",
        "*She bites down hard on your shoulder, drawing blood.* Filth!",
        "*Her eyes blaze with fury as you overpower her struggles.* I won't break!",
        "*She wrenches one arm free and punches your side.* Get off!",
        "*Her voice is a low growl of hatred.* I'll never forgive this.",
        "*She tries to knee you in the groin, but you block it.* Fucker!",
        "*Her body shivers with rage, not pleasure.* You'll regret this.",
        "*She glares defiantly as you force another thrust.* Is that all you've got?",
        "*Her muscles tense, resisting your invasion.* I won't submit!",
        "*She tries to push you away with surprising strength.* Get... off!"
    },
    default_zombie = {
        "*her cold, rotting pussy envelops your cock* Nnnnhh...",
        "*putrid stench fills the air as you thrust into her dead flesh* Grrrh...",
        "*her cold, stiff fingers grasp your balls clumsily* Hrrrrnnngh...",
        "*her milky eyes stare blankly as you pound her decaying hole* Urrrgh...",
        "*her rotting jaw hangs open, dripping black fluid* Gaaaah...",
        "*her decomposing body presses against you as you penetrate her* Mnnngh...",
        "*black ichor seeps from her wounds, lubricating your cock* Hrrrauugh...",
        "*her stiff movements grind her rotten cunt against you* Mmmrrr...",
        "*pieces of skin slough off with each thrust into her cold hole* Gnnnnhh...",
        "*her dead weight pushes down on your cock as you impale her* Grrnnnhh...",
        "*her fetid breath washes over you as you fuck her lifeless body* Haaaaah...",
        "*her uncoordinated thrusts drive your cock deeper into her decaying pussy* Hnnnggg...",
        "*necrotic tissue rubs roughly against your shaft* Hrrrghh...",
        "*her jagged nails dig into your flesh as you pound her rotten hole* Uuuungh...",
        "*her rigor mortis muscles twitch and squeeze your cock* Gnnnaahh..."
    },
    nurse_bot = {
        "*Synthetic skin warms against yours as lubricants whir.* Subject vital signs: elevated. Proceeding.",
        "*Internal mechanisms adjust grip parameters.* Optimal pressure achieved. Continue stimulation.",
        "*Optical sensors track micro-expressions.* Subject experiencing pleasure threshold alpha. Increasing thrust vector.",
        "*Her metallic joints whir softly with each movement.* Lubricant levels optimal. Engaging pelvic rotation sequence.",
        "*Temperature sensors register localized heat increase.* Bio-feedback loop positive. Maintain rhythm.",
        "*Voice synthesizer emits a low hum.* Analyzing subject response... Positive. Increase intensity.",
        "*Her programmed movements become more vigorous.* Pleasure protocol initiated. Calculating optimal frequency.",
        "*Internal actuators pulse rhythmically.* Target stimulation point engaged. Maintaining contact.",
        "*She emits a series of soft beeps and clicks.* Subject nearing peak neurological response. Prepare for energy transfer.",
        "*Her chassis trembles slightly.* System analysis: Pleasure levels exceeding standard parameters.",
        "*Positronic brain analyzes your movements.* Adapting internal contouring for maximum stimulation.",
        "*Her optical sensors glow brighter.* Recording physiological data. Subject reaction: Optimal.",
        "*She grips you with precise, measured strength.* Warning: Structural integrity approaching maximum load.",
        "*Her internal fans whir faster.* Core temperature rising. Pleasure cycle reaching peak.",
        "*She emits a simulated gasp.* Energy exchange protocol initiated. Stand by for discharge.",
        "*Synthetic pheromones released.* Subject compliance protocols engaged. Deepen connection.",
        "*Her movements mirror yours perfectly.* Adaptive learning matrix engaged. Optimizing pleasure delivery.",
        "*She whispers diagnostic data.* Heart rate: Elevated. Respiration: Accelerated. Dopamine levels: Peaking.",
        "*Her internal reservoirs prepare for discharge.* Final sequence initiated. Brace for energy release."
    },
    succubus = {
        "*her eyes glow with intense desire as she rides your cock* Mmm~ Your energy and cum are intoxicating, Master~",
        "*her wings tremble as she bounces on your shaft* Yes... please, Master, fill my demonic pussy more~",
        "*her fangs glisten as she submits, her wet cunt gripping you* Your taste and your cock... better than I imagined~",
        "*her tail coils around your balls as you pound her* I-I'm yours to command, Master~ Use my holes~",
        "*her gentle caress on your cock* Does my tight pussy please you, Master?~",
        "*she shivers with delight as you stretch her demonic hole* Y-you make me feel things I never...",
        "*she licks your shaft hungrily* Master's cock is so... overwhelming~",
        "*her wings flutter as you thrust deep inside her* M-master's cock makes me dizzy with pleasure~",
        "*she looks up adoringly as you fuck her mouth* No one has ever filled me like this~",
        "*she trembles as your cock pulses inside her* Am I... am I draining you well, Master?~",
        "*she whimpers as you penetrate her ass* Please don't stop... I need more of your seed~",
        "*she presses her breasts against you as you fill her womb* Your corruption... it fills me completely~",
        "*her eyes glaze as your energy transfers into her* Master's cock is changing me~",
        "*she gasps as you slam into her demonic pussy* W-what are you doing to my body, Master?~",
        "*she submissively nuzzles your cock* Just a taste of your power and cum... please~",
        "*she moans helplessly as you dominate all her holes* The way you fill me... it's perfect~",
        "*she poses seductively, spreading her wet lips* Do I please you like this, Master?~",
        "*she loses control as you flood her womb* Y-your cum... it's too much power~",
        "*she whispers breathlessly as you pull out* I can feel your darkness dripping from me~"
    },
    demon_schoolgirl = {
        "*her uniform rustles as you thrust under her skirt* S-senpai... your cock is so big inside me~",
        "*her horns glow faintly as you stretch her tight pussy* T-this feels so good... you're rearranging my insides...",
        "*her tail wags excitedly as you pound her from behind* D-don't stop... fuck me harder!",
        "*her wings flutter nervously as your cock hits her cervix* I-I can't control myself when you're so deep...",
        "*her fangs nibble your neck as she rides your shaft* M-more... please fill my demonic pussy...",
        "*demonic energy crackles around her pussy as you thrust* Y-you're making my unholy hole feel things...",
        "*she adjusts her skirt to give you better access* S-should we be doing this in the classroom?",
        "*she blushes intensely as you bend her over her desk* I-I've never had a cock this big before~",
        "*her glasses fog up as you pound her virgin pussy* Oh... oh my~ You're making me cum~",
        "*she clutches schoolbooks to chest as you fuck her standing* This is better than studying~ Your cock teaches me so much~",
        "*her tail curls around your leg as you fill her womb* S-senpai's hot cum is inside me~",
        "*demonic sigils appear on her skin as you thrust* M-my powers are reacting to your cock~",
        "*she tries to stay quiet as you take her against the lockers* W-what if someone hears us fucking?",
        "*her school tie comes loose as you pound her tight ass* Is anal sex against school rules too?",
        "*her small horns pulse with energy as you flood her womb* Y-you're awakening my demonic side with your cum~",
        "*she checks her watch as you thrust between her thighs* W-we might miss next period~ Keep fucking me anyway~",
        "*she giggles nervously as you expose her demonic pussy* D-do you like corrupting girls like me?",
        "*she twirls her hair as your cock throbs inside her* I've been wanting your dick all semester~",
        "*her magical aura flares as your cum fills her* I'm learning so much about pleasure from you~"
    },
    anthro = {
        "*her tail wags excitedly as your cock penetrates her wet slit* Ruff~ More please! Breed me!",
        "*her ears perk up as you pound her animal pussy* Mrow~ That cock feels amazing in my heat~",
        "*she purrs contentedly as your shaft stretches her tight hole* Don't stop now~ Fuck your animal mate~",
        "*she nuzzles against you as her slick pussy grips your length* So good... your cock fits perfectly~",
        "*she growls playfully as you mount her from behind* Keep going~ Rut me like an animal~",
        "*she whines with pleasure as you hit her deepest parts* Yes... more... knot me!",
        "*her fur bristles with excitement as your scent mixes with her juices* Your smell is driving my animal side wild~",
        "*she paws at your chest as you thrust into her* Take me like the animal I am~ Fill my breeding hole~",
        "*she sniffs deeply at your crotch* I can smell your arousal~ Let me taste your cock~",
        "*her ears flatten in submission as you pound her dripping pussy* I'm yours to command~ Use my animal body~",
        "*she howls softly as your cock triggers her mating instinct* My heat is taking over~ I need your seed~",
        "*she licks your neck as her pussy clenches around you* You taste so good~ Your cock feels even better~",
        "*her body tenses as you thrust deeper* I'm entering my heat~ Fill me with your cum~",
        "*her eyes dilate as you ravage her animal cunt* My animal side needs your seed deep inside~",
        "*she rubs her scent glands against you as you fill her* Mark me with your scent and cum~",
        "*she makes territorial sounds as your cock claims her depths* You belong to me now~ Your cock is mine~",
        "*her teeth bare slightly as her pussy milks your shaft* I want to feel your bite as you breed me~",
        "*her claws extend gently into your back as you thrust* Let me mark you while you fill my womb~",
        "*her snout nuzzles your neck as her animal pussy squeezes your cock* Your pulse is racing~ Cum inside me~"
    },
    daughter = {
        "*she gasps as your cock fills her tight pussy* Daddy... this feels so good inside me...",
        "*her tight walls grip you as you thrust* I... I can't control myself with your big cock...",
        "*her wet slit squeezes around your shaft* More... please Daddy... deeper...",
        "*her young body trembles as you penetrate her* You're making me feel things no boy ever has...",
        "*her thighs quiver as you thrust* This is wrong... but your cock feels so right...",
        "*her virgin pussy stretches around you* I need you... so much Daddy...",
        "*she looks up nervously as you fill her* Is this okay, Daddy? Am I taking your cock right?",
        "*her body trembles as you push deeper* You make me feel so special with your cock inside me...",
        "*she clutches your arm as you thrust* I've wanted your cock for so long...",
        "*she whispers as her pussy tightens* Our secret, right Daddy? No one can know you're inside me?",
        "*her innocent eyes watch your cock slide in* Am I doing it right? Does my pussy feel good?",
        "*her hesitant touches guide your shaft* Show me how to please you Daddy...",
        "*she blushes deeply as you fill her* No one makes my little pussy feel like you do...",
        "*she bites her lip as you thrust* I've been so curious about your cock...",
        "*she moans softly* This is much better than with boys my age... they don't fill me like you...",
        "*she clings tightly as you pump into her* Don't leave me... keep your cock inside...",
        "*her voice wavers as you hit deeper* I want to make you proud of how I take your cock...",
        "*she smiles shyly as you stretch her* Do you like me like this? With your cock in your little girl?",
        "*she gasps breathlessly as you thrust* I never knew it could feel this way with you inside me..."
    },
    zed_survivor = {
        "*her tattered gear clanks as you pound her cold pussy* Unngghhh...",
        "*her clouded eyes roll back as your cock penetrates her decayed entrance* Hrrrnnnghh...",
        "*her cold hands grip your shaft with military precision* Grrrrnnngh...",
        "*her decaying body responds mechanically as you thrust between her rotting thighs* Mmmrrrhhh...",
        "*her broken armor grinds against your skin as you fuck her from behind* Nnnnghh...",
        "*her body moves with motor memory as your cock plunges into her cold depths* Hrrrgh...",
        "*her survival instincts manifest as her dead pussy tightens around your shaft* Urrrgh...",
        "*her tactical vest scrapes against your chest as you pound her rotten hole* Gaaahh...",
        "*putrid fluids leak from her wounds, lubricating your thrusts* Mrrrgh...",
        "*her zombie moans take on primal quality as you fill her decayed womb* Guuungh...",
        "*her combat boots kick spasmodically as you pound her undead cunt* Hrrrrauugh...",
        "*her gunbelt rattles with each violent thrust into her cold depths* Mrrrph...",
        "*her vacant eyes briefly flutter as your cock stretches her rotting hole* Hhhhrrrngh...",
        "*her survival gear digs into your flesh as you ravage her undead body* Grrrhnnn...",
        "*her undead muscles lock in orgasmic rigor around your throbbing cock* HRRRRNGH!",
        "*her holster slaps rhythmically against her thigh as you pound her from behind* Gmmmrrgh...",
        "*her torn combat fatigues catch on your skin as you thrust into her cold pussy* Arrrghh...",
        "*her grimy tactical gloves leave dirty streaks as she grips your ass* Hrrrrgh...",
        "*cold dead fluid spills from her decaying pussy as you pull out* Hnnnnghh..."
    },
    mon_broken_cyborg = { -- New entry
        "*Metallic grinding sounds accompany erratic thrusts as your cock penetrates the cyborg's artificially lubricated opening.* ERROR: UNEXPECTED INPUT.",
        "*Sparks fly from damaged joints as the cyborg's synthetic vagina spasms around your shaft.* MALFUNCTION... PLEASURE CIRCUITS... OVERLOADED...",
        "*Its optical sensors flicker erratically as you thrust into its modified lower parts.* WHY? DATA... CORRUPTED... BUT... FEELS... GOOD...",
        "*A broken voice whispers, interspersed with static as you penetrate deeper.* I... was... human... *bzzt*... STILL... FEEL...",
        "*It slams against you with uncontrolled force, impaling itself on your cock.* SELF-PRESERVATION OVERRIDE... *click*... REPRODUCTION PROTOCOLS ACTIVE...",
        "*Wires spark near its groin as your member pushes into the wet synthetic opening.* SENSORY INPUT... OVERLOAD... REBOOTING...",
        "*Its metal hand grips your cock painfully tight before guiding you inside.* CONNECTION ESTABLISHED... INITIATING... PLEASURE SEQUENCE...",
        "*A monotone electronic voice as your cock slides in and out.* PLEASE... CONTINUE... PROCESSING... PLEASURE...",
        "*Its head twitches violently as you penetrate its modified orifice.* WHAT... HAVE... YOU... DONE... TO... ME? MORE...",
        "*Oil and synthetic lubricant leak from where you're penetrating.* THIS UNIT... IS... FUNCTIONING... AS... INTENDED...",
        "*It shudders violently around your member.* INITIATING... ORGASM... SUBROUTINE... *whirr* SUCCESS.",
        "*The human part of its face twists in pleasure as you thrust into its wet opening.* HUMAN... SENSATION... RESTORED...",
        "*Random static bursts from its speaker as you penetrate deeper.* REPRODUCTIVE... SYSTEMS... FUNCTIONAL... PROCEEDING...",
        "*Its synthetic vagina grips your cock with mechanical precision.* MAXIMIZING... PLEASURE... OUTPUT...",
        "*A faint, distorted moan escapes as you thrust into its modified opening.* CONTINUE... DATA... COLLECTION..."
    },
    mon_prototype_cyborg = { -- New entry
        "*Its movements are precise as it rides your cock with mechanical efficiency.* Is this... perfection?",
        "*A single tear leaks from its organic eye as your member penetrates its wet opening.* I didn't... ask for this... but I need it...",
        "*Its synthetic vagina feels unnervingly smooth around your cock.* This body... responds... correctly.",
        "*It shudders slightly as you penetrate deeper.* Analyzing... bio-feedback... pleasure confirmed.",
        "*A whisper as you thrust into its modified orifice.* Let me feel... human... again...",
        "*Its internal fans whir softly as your cock slides in and out.* Optimizing... response... for maximum stimulation.",
        "*It flinches as you touch a surgical scar near where you're penetrating.* Integration... still... processing...",
        "*Its synthetic muscles grip your member with perfect pressure.* This... is what I was made for...",
        "*A flicker of pleasure crosses its face as you penetrate deeper.* Sensation... restored... continue...",
        "*It produces a perfect moan as your cock fills its modified opening.* Pleasure protocols... engaging...",
        "*Its eyes roll back as your member hits something inside.* Processing... intense... stimulation...",
        "*A sudden jolt runs through its body, tightening around your cock.* System optimizing... pleasure response...",
        "*It rides you with mechanical strength, its synthetic vagina pulsing.* Maximum... stimulation... achieved...",
        "*A soft click emanates from its chest as you thrust deeper.* Sexual function... optimal... proceeding...",
        "*Its synthetic fluids coat your member as you penetrate its modified opening.* Lubrication systems... functioning... perfectly..."
    },
    threesome = {
        generic = {
            "Oh yes... both of you...",
            "This feels amazing...",
            "I can't handle both of you...",
            "More... from both of you...",
            "You're both so good...",
            "I want both of you...",
            "*overwhelmed gasp* Too much... but don't stop...",
            "*moans loudly* Yes... right there... both of you...",
            "*caught between bodies* I've never felt so complete...",
            "*eyes flutter* I don't know who to focus on...",
            "*surrenders control* Take me however you want...",
            "*body quivers* Four hands... too much pleasure...",
            "*looking back and forth* I can't decide who feels better...",
            "*reaches for both* I need to touch you both...",
            "*breathless laugh* This is intense...",
            "*sandwiched between bodies* So full...",
            "*climaxes intensely* Both of you... together...",
            "*whispers* I never imagined it could be like this...",
            "*guides your movements* Yes, like that, while you... yes..."
        },
        succubus = {
            "*eyes glow mischievously* Two toys to play with? Lucky me~",
            "*wings flutter excitedly* Double the fun, double the pleasure~",
            "*giggles wickedly* I get to have both of you? Best day ever~",
            "*fangs glint in a smile* Ooh~ Two treats for little ol' me~",
            "*tail wraps around both playfully* Got you both now, tee-hee~",
            "*claws trace both teasingly* Eenie, meenie, miney... both!~",
            "*bounces between you* This is like a buffet for me~",
            "*winks at both* Which one of you tastes better, I wonder?~",
            "*strikes a pose* Two admirers for my beauty? I'm flattered~",
            "*giggles at your expressions* Your faces when I touch you both~",
            "*playful competition* Let's see who can please me better~",
            "*dramatic sigh* It's so hard being this irresistible~",
            "*floats above both* I have centuries of experience for you both~",
            "*blows kisses* Enough love to go around~",
            "*pretends to be overwhelmed* Oh my~ Two at once? How will I manage?~",
            "*fake innocent look* Is this your first threesome? Let me guide you~",
            "*teasing laugh* Are you two getting jealous of each other?~",
            "*creates a small heart illusion* There's room in here for both~",
            "*playful smack* Don't worry, I'll give equal attention~"
        },
        demon_schoolgirl = {
            "*uniform rustles* T-two of you... I can't...",
            "*horns glow brightly* S-so much energy...",
            "*wings flutter rapidly* I-I'm losing control...",
            "*tail wags excitedly* B-both of you... too much...",
            "*fangs nibble both* M-more... from both...",
            "*demonic energy crackles* T-this is too intense...",
            "*tries to cover face* T-this isn't in any textbook...",
            "*magical energy flares uncontrollably* Y-you're awakening my powers~",
            "*struggles with uniform* H-how do I position for both of you?",
            "*clutches schoolbooks awkwardly* Is this allowed in d-detention?",
            "*whispers nervously* What if the teachers find out?",
            "*demonic symbols glow on skin* M-my demonic nature is emerging~",
            "*caught between experienced touches* S-senpai, you're both teaching me so much~",
            "*school tie comes completely undone* I'm breaking all the rules today~",
            "*looks at watch in panic* W-we're missing all our classes~",
            "*small horns grow visibly* T-this is accelerating my transformation~",
            "*tries to take notes mentally* I'll remember everything you teach me~",
            "*awkwardly positions herself* L-like this? And you go there?",
            "*overwhelmed but eager* I want to learn everything from both of you~"
        },
        anthro = {
            "*tail wags excitedly* Two mates~ So good~",
            "*ears perk up* Double the fun~",
            "*purrs loudly* Both of you... amazing~",
            "*nuzzles both* So much love~",
            "*growls playfully* Two to play with~",
            "*whines with pleasure* Both of you... perfect~",
            "*instincts take over* My animal side needs both of you~",
            "*marks both with scent* You're both part of my pack now~",
            "*animal sounds intensify* Breeding with two mates~",
            "*fur stands on end* Overwhelming sensations~",
            "*alternates between dominance/submission* Taking turns as alpha~",
            "*keen senses overwhelmed* Too many scents and touches~",
            "*paws at both frantically* Need... both... now~",
            "*eyes show wild abandon* My feral side is emerging~",
            "*instinctive positioning* Perfect mating arrangement~",
            "*territorial growling* Both of you belong to me~",
            "*scent marking intensifies* Everyone will know you're mine~",
            "*primal sounds* The pack mates as one~",
            "*claws extend slightly* I'll mark both as territory~"
        },
        daughter = {
            "Daddy... and you... this is...",
            "I can't handle both of you...",
            "This is wrong... but feels so right...",
            "Two of you... it's too much...",
            "I need both of you...",
            "You're both making me feel things...",
            "*overwhelmed innocence* I never imagined my first time like this...",
            "*looks between both* Who should I focus on?",
            "*innocent confusion* Show me how to please you both...",
            "*whispers* Our special secret between the three of us...",
            "*tries to impress* Am I doing it right for both of you?",
            "*overwhelmed senses* I don't know where to look or touch...",
            "*nervous giggles* Is this how grown-ups always do it?",
            "*shy determination* I want to make you both happy...",
            "*innocent question* Can we do this again tomorrow?",
            "*wide-eyed* I never knew it could be like this...",
            "*trying to be mature* I can handle both of you, I promise...",
            "*alternating attention* First you, then you...",
            "*caught in the middle* I feel so special with both of you..."
        },
        zed_survivor = {
            "*tattered gear clanks from both sides* Unnnggghh...",
            "*sandwiched between cold undead flesh* Hrrrgh... Mrrrngh...",
            "*tactical gear scrapes painfully from both directions* Grrrngh... Hrrrgh...",
            "*broken armor pinches from both sides* Nggghh... Mrrrhh...",
            "*mottled hands explore with military precision* Unnnghhh... Mrrrauugh...",
            "*milky eyes stare through you from both sides* Hrrrgh... Graaah...",
            "*combat boots stomp in mindless rhythm* Hrrrgh... Mrrgghh...",
            "*holsters and gear clatter against bone* Gaaaahhh... Urrrrgh...",
            "*guttural moans echo between zombies* Mrrrphh... Hrrrrngh...",
            "*undead survivors coordinate with residual training* Hrrrgh... Urrrngh...",
            "*faces locked in death grimaces* Nrrrghh... Mrrrgh...",
            "*black bile drips from multiple wounds* Unnnghhh... Grrnghh...",
            "*cold grip tightens with undead strength* Mrrrhnnn... Gnnnghhh...",
            "*survivor zombies mirror each other's death throes* Grrngh... Mrrnghh...",
            "*wounds flex and stretch, leaking fluids* Hrrrgh... Nrrrghh...",
            "*tactical gear squeaks against rotting flesh* Gaaaahhh... Urrrngh...",
            "*combat instincts emerge through death's veil* Mrrrghh... Hrrrngh...",
            "*weapons training evident in methodical thrusts* Grrrnngh... Mrrrhnnn...",
            "*cold dead seed pumps from decaying organs* HRRRRNGH! URRRGHHH!"
        }
    },
    mon_succubi_lactophilia = { -- New entry for milkcubus
        "*Her heavy breasts sway as you move, dripping milk onto both of you.* Mmm~ Drink up, little one~",
        "*She presses her overflowing bosom against your chest, coating you in warm milk.* Does mother's milk please you?~",
        "*Her nipples harden and leak as you thrust into her.* Y-yes... drain me completely~",
        "*She guides your head to her breast while you're inside her.* Take it all... my essence and my milk~",
        "*Warm milk dribbles down your chin as she milks herself onto you.* So thirsty... drink it all~",
        "*Her insides clench around you as milk sprays from her nipples.* I'm overflowing for you~",
        "*She sighs contentedly as you pound her, milk weeping from her areolas.* Nurturing you feels so right~",
        "*Her body shivers as you stimulate her from within and without.* M-my milk... it's reacting to you~",
        "*She offers you a swollen nipple as you find your rhythm.* Taste me while you take me~",
        "*Her back arches, pushing her milk-heavy breasts against you.* Fill me up while you drink me down~",
        "*She whimpers, clutching you tightly as milk flows freely.* I need you to drain me... both ways~",
        "*Her gaze is hazy with pleasure and maternal instinct.* My good little nursling~",
        "*She squeezes her breasts, coating your shaft in slick milk.* Better lubrication, yes?~",
        "*Her whole body trembles as she nears climax, milk spraying erratically.* I'm coming... drink my offering~",
        "*She pulls you closer, whispering sweet, milky nothings.* Be a good baby and take it all~",
        "*Her pussy pulses around you, mirroring the ache in her breasts.* Empty me... completely~",
        "*She traces patterns on your skin with her milky fingers.* Marked by mother's love~",
        "*She moans softly, her body slick with sweat and milk.* This bond... it's intoxicating~",
        "*She nuzzles against you, offering her dripping nipple like a reward.* Good boy~ Have some more~"
    }
}
--todo: perhaps move these dialog lines out of const into json so we could randomize words and add gender-specific and etc checks?
--another problem is that you can still hear this even when deaf
--[[レイダー的な敵キャラ会話のテキスト]]--
--[[レイダー的な敵キャラ会話のテキスト]]--
VULGAR_SPEECH_TEXTS = {
    -- Default fallback for any monster
    DEFAULT = {
        TARGET_ACQUIRE = {
            "\"Found you!\"",
            "\"Fresh prey!\"",
            "\"I see you there!\""
        },
        TARGET_ENGAGE = {
            "\"You're mine now!\"",
            "\"Let's have some fun!\"",
            "\"Don't struggle too much!\""
        },
        TARGET_LOST = {
            "\"Where did you go?\"",
            "\"Don't hide from me!\"",
            "\"I'll find you eventually!\""
        },
		WIFE_U = {
			"\"Time to make you mine!\"",
			"\"I'll show you true pleasure...\"",
			"\"Your body belongs to me now!\""
		},
		WIFE_U_CUM = {
			"\"Yes! Give in to the pleasure!\"",
			"\"That's it! Release yourself!\"",
			"\"Your essence is delicious!\""
		},
		STRIP_success = {
			"\"I'll take ITEMNAME off you now!\"",
			"\"Let me help you undress...\"",
			"\"You won't be needing ITEMNAME anymore!\""
		},
		STRIP_naked = {
			"\"Already naked for me? How thoughtful!\"",
			"\"No clothes to remove? Perfect!\"",
			"\"I see you came prepared...\""
		},
		STRIP_resist_dodge = {
			"\"Stop squirming! I just want to undress you!\"",
			"\"Hold still while I remove these clothes!\"",
			"\"You can't dodge forever!\""
		},
		STRIP_resist_strength = {
			"\"Strong, aren't you? But not strong enough!\"",
			"\"Your strength is impressive, but mine is greater!\"",
			"\"Stop resisting! These clothes are coming off!\""
		},
		STRIP_dodge_uncanny = {
			"\"So quick! I love a chase!\"",
			"\"Your reflexes are impressive, but I'll catch you eventually!\"",
			"\"Playing hard to get? How exciting!\""
		},
        WIFE_U_START = {  -- Added DEFAULT WIFE_U_START
            "\"%s pins you down and slowly eases into you before joining your bodies together...\"",
            "\"%s forces you to the ground and mounts you with a hungry look...\"",
            "\"%s tackles you to the ground and begins taking your body without hesitation...\"",
            "\"%s pushes you against the wall and takes you from behind with forceful thrusts...\"",
            "\"%s embraces you tightly before penetrating you with a fluid motion...\"",
            "\"%s grabs you firmly and begins coupling with animalistic intensity...\""
        }
    },
    
    -- Original generic lines
    TARGET_ACQUIRE = {
        "\"Bah!\"",
        "\"Aa-haaa!\"",
        "\"Gotcha loser!\"",
        "\"What the--?!\"",
        "\"Hey, it's the enemy!\"",
        "\"We have contact!\"",
        "\"Hostiles!\"",
        "\"Ha! I see ya!\"",
        "\"Hyahaaa!\"",
        "\"I'm gonna twist your head off and make it my toy!\"",
        "\"Hyahaaa! Fresh toy!\"",
        "\"Hyahaaa! Fresh meat!\"",
        "\"We're gonna feast on human flesh today!\"",
        "\"It's raaaape tiiiiiime!\"",
        "(Insane laughter)",
        "\"HELL YEAH!\"",
        "\"Give 'em hell!\""
    },
    TARGET_ENGAGE = {
        "\"Hyahaaa!\"",
        "\"Scared, huh?!\"",
        "\"Come at me, bitch!\"",
        "\"Blood! Blood! Blooooooooood!!!\"",
        "\"Bleed for meeee!\"",
        "\"You're nothiiiiiiiiiiiiiiiiiiiin'!\"",
        "\"You got nothin' on me!\"",
        "\"Rape and then kill? Or kill and then rape?  ...Both sound reaaaaaaaally nice!\"",
        "\"I'll rape you, then kill you, and then rape you again!\"",
        "\"Murder death kill!\"",
        "\"I don't mind helpin' you out, you know?  ...After I'm done toyin' with ya, that is!\"",
        "(Insane laughter)",
        "(Roars)",
        "(Howls)",
        "(Growls)",
        "\"Dieeeeeeeeeeeee!\"",
        "\"Imma fuck you up!\"",
        "\"I just want to play! You don't mind it, right?!\"",
        "\"You little shit...\"",
        "\"How are you still not dead?!\"",
        "\"Why can't you just die?!\"",
        "\"This ain't my first time killin', ya rookie!\"",
        "\"If I can't live as a Human, then Demon life it is!\"",
        "\"When you get to hell, tell 'em I sent ya!\"",
        "\"When I kill you, I'll rape your corpse! Don't worry, I'll be gentle!\"",
        "\"You're gonna be really fuckin' sorry!\""
    },
    TARGET_LOST = {
        "(Clicks tongue)",
        "\"That fellow sure runs fast...\"",
        "\"That moron is hella fast, damn!\"",
        "\"Come out, come out, wherever you are! I'm gonna end ya quick!\"",
        "\"Stop hidin' and come out already!\"",
        "\"Careful, that fellow is still hidin' nearby...\"",
        "\"Stop runnin'!\"",
        "\"Damn, where the fuck did he go?!\"",
        "\"I see ya! No I don't... Yes I do! No I don't... Fuck!\"",
        "\"Chicken, chicken, chicken... Chicken!\""
    },
    
    -- Monster-specific speech patterns
-- Monster-specific speech patterns

-- Monster-specific speech patterns
mon_cambion_female = {
    TARGET_ACQUIRE = {
        "\"Oh, a new plaything!\"",
        "\"What a delicious find!\"",
        "\"You can't escape me!\"",
        "\"Fresh meat wandering into my domain...\"",
        "\"I smell your fear already!\"",
        "\"A willing sacrifice appears!\"",
        "\"Your soul will taste divine...\"",
        "\"The hunt begins!\"",
        "\"You've stumbled into the wrong territory!\"",
        "\"I've been waiting for someone like you!\""
    },
    TARGET_ENGAGE = {
        "\"I'll drain your essence!\"",
        "\"Submit to me!\"",
        "\"Your struggles excite me!\"",
        "\"You're mine to play with now!\"",
        "\"Feel my demonic power!\"",
        "\"Half-demon, all desire!\"",
        "\"Your resistance is pointless and arousing!\"",
        "\"I was born to dominate mortals like you!\"",
        "\"My demonic heritage demands your submission!\"",
        "\"Your fear makes you even more appealing!\""
    },
    TARGET_LOST = {
        "\"Playing hard to get?\"",
        "\"I can smell your fear!\"",
        "\"Run all you want, I'll find you!\"",
        "\"Hide if you must, I enjoy the hunt!\"",
        "\"Your scent lingers in my nostrils...\"",
        "\"Hiding only delays our inevitable union!\"",
        "\"I've tracked prey for centuries, mortal!\"",
        "\"The chase makes the capture sweeter!\"",
        "\"Your fear leaves a trail I can follow!\"",
        "\"How adorable, thinking you can escape me!\""
    },
    WIFE_U = {
        "\"I'll drain you dry, mortal!\"",
        "\"Your body is mine to use as I please!\"",
        "\"Surrender to my demonic embrace!\"",
        "\"I'll show you pleasures beyond mortal imagination!\"",
        "\"Let me corrupt you completely!\"",
        "\"Your resistance only makes this more enjoyable!\"",
        "\"I'll extract every drop of your essence!\"",
        "\"Half human, but fully dominant!\"",
        "\"Relax and give in to my power...\"",
        "\"Your soul is forfeit, but oh so worth it!\""
    },
    WIFE_U_CUM = {
        "\"Yes! Feed me your essence!\"",
        "\"Your pleasure sustains me!\"",
        "\"Your soul belongs to me now!\"",
        "\"Such sweet nectar you provide!\"",
        "\"I can feel your life force flowing into me!\"",
        "\"Each drop strengthens my demonic half!\"",
        "\"This union marks you as mine forever!\"",
        "\"Your climax feeds my infernal hunger!\"",
        "\"I'll take everything you have to give!\"",
        "\"Your essence will sustain me for days!\""
    },
    STRIP_success = {
        "\"These clothes are in my way...\"",
        "\"Let me see what's underneath these garments!\"",
        "\"ITEMNAME will look better on the floor!\"",
        "\"Mortal coverings are such a nuisance!\"",
        "\"Let me unwrap my prize slowly...\"",
        "\"These barriers between us must be removed!\"",
        "\"ITEMNAME is hiding what belongs to me!\"",
        "\"Your flesh should be exposed to my gaze!\"",
        "\"Let me peel away this ITEMNAME...\"",
        "\"Clothes are for the innocent, which you no longer are!\""
    },
    STRIP_naked = {
        "\"Already exposed for me? How eager!\"",
        "\"I see you've prepared yourself for our union!\"",
        "\"Naked and vulnerable... perfect!\"",
        "\"Your bare flesh calls to my demonic desires!\"",
        "\"How thoughtful to present yourself ready!\"",
        "\"A willing victim requires no undressing!\"",
        "\"Displaying yourself for my pleasure? Wise choice!\"",
        "\"Your nakedness is a suitable offering to me!\"",
        "\"Ah, you know what demons crave!\"",
        "\"Bare and ready for corruption... excellent!\""
    },
    STRIP_resist_dodge = {
        "\"Hold still, little mortal!\"",
        "\"Your struggles only excite me more!\"",
        "\"I love it when they resist!\"",
        "\"Stop squirming! It only delays the inevitable!\"",
        "\"The hunt makes the capture all the sweeter!\"",
        "\"Your evasion is amusing but futile!\"",
        "\"Playing hard to get? I enjoy a challenge!\"",
        "\"Swift movements won't save you from a cambion!\"",
        "\"Dance all you want, my prey!\"",
        "\"Your agility is impressive, but mine is demonic!\""
    },
    STRIP_resist_strength = {
        "\"Such strength! But futile against a demon like me!\"",
        "\"Your resistance feeds my desire!\"",
        "\"Strong, but not strong enough to resist my will!\"",
        "\"Impressive power for a mortal! But I am half-demon!\"",
        "\"Your strength makes this so much more interesting!\"",
        "\"Fight all you want, it only heightens my pleasure!\"",
        "\"I love breaking the strong ones!\"",
        "\"Your might is nothing against infernal strength!\"",
        "\"Such delicious defiance! It will make your surrender sweeter!\"",
        "\"Struggle harder! Show me your mortal limits!\""
    },
    STRIP_dodge_uncanny = {
        "\"Quick little thing, aren't you?\"",
        "\"The chase makes the capture all the sweeter!\"",
        "\"I enjoy hunting my prey!\"",
        "\"Supernatural reflexes? How exciting!\"",
        "\"Your evasion is remarkable, but temporary!\"",
        "\"Few can dodge a cambion for long!\"",
        "\"Such skill! You'll be even more satisfying to catch!\"",
        "\"I haven't had prey this elusive in centuries!\"",
        "\"Your agility only heightens my hunting instinct!\"",
        "\"You can't outmaneuver demonic reflexes forever!\""
    },
    WIFE_U_START = { -- Added mon_cambion_female WIFE_U_START
        "\"%s knocks you down with inhuman strength, straddling you with demonic hunger in her eyes...\"",
        "\"%s throws you against a wall before pressing her body against yours with predatory intent...\"",
        "\"%s tackles you to the ground, her corrupted form pinning you down as she begins to take you...\"",
        "\"%s grabs you with surprising force, positioning herself to claim what she desires...\"",
        "\"%s slams you to the ground with a growl, her half-demonic eyes glowing as she mounts you...\"",
        "\"%s overpowers you with ease, forcing you into position as she prepares to mate...\""
    }
},

mon_succubi = {
    TARGET_ACQUIRE = {
        "\"Oh my, what a delight!\"",
        "\"Hello there, darling~\"",
        "\"Mmm, you look tasty~\"",
        "\"I've been searching for someone like you!\"",
        "\"What a delicious soul you have!\"",
        "\"Your aura calls to me, sweetling!\"",
        "\"Fresh essence, ripe for the taking!\"",
        "\"You'll do perfectly for my needs~\"",
        "\"I can already taste your desire!\"",
        "\"A new plaything has wandered my way!\""
    },
    TARGET_ENGAGE = {
        "\"Don't resist the pleasure!\"",
        "\"Let me taste you~\"",
        "\"Your soul will be mine!\"",
        "\"Surrender to ecstasy!\"",
        "\"Your resistance is adorable and futile!\"",
        "\"I promise this will feel divine~\"",
        "\"Let me show you what a succubus can do!\"",
        "\"Your fear and desire are equally delicious!\"",
        "\"I'll drain you so sweetly you'll beg for more!\"",
        "\"This won't hurt... much!\""
    },
    TARGET_LOST = {
        "\"Playing hard to get? How cute!\"",
        "\"I'll find you, my sweet!\"",
        "\"You can't run from desire forever!\"",
        "\"Hide all you want, I can smell your lust!\"",
        "\"Our dance has just begun, darling!\"",
        "\"Your soul calls to me - I will find you!\"",
        "\"Fleeing only makes the hunt more thrilling!\"",
        "\"Even in hiding, your dreams will betray you to me!\"",
        "\"Run, run, as fast as you can... I'll still catch you!\"",
        "\"Your desire leaves a trail I can follow!\""
    },
    WIFE_U = {
        "\"Let me show you ecstasy beyond mortal comprehension~\"",
        "\"Your pleasure is my sustenance, darling~\"",
        "\"Give yourself to me completely!\"",
        "\"I'll take your essence in the most delightful way!\"",
        "\"Your body and soul are mine to feast upon!\"",
        "\"Surrender to the bliss only a succubus can provide!\"",
        "\"Let me drain you to the very last drop~\"",
        "\"You'll forget all else but the pleasure I give you!\"",
        "\"I've waited centuries for essence as sweet as yours!\"",
        "\"This union will be legendary, even in hell!\""
    },
    WIFE_U_CUM = {
        "\"Yes, release your essence into me!\"",
        "\"Your soul's energy is so delicious!\"",
        "\"Feed me with your pleasure!\"",
        "\"Your climax strengthens my immortality!\"",
        "\"Such potent life force you provide!\"",
        "\"I can feel your essence flowing into me!\"",
        "\"Your surrender is complete and exquisite!\"",
        "\"This is but the first of many such feedings!\"",
        "\"Your ecstasy is my ambrosia!\"",
        "\"Give me everything... yes, that's it!\""
    },
    STRIP_success = {
        "\"These clothes are just barriers between us~\"",
        "\"Let's remove this troublesome ITEMNAME, shall we?\"",
        "\"Allow me to undress you, my sweet~\"",
        "\"ITEMNAME is hiding treasures I wish to explore!\"",
        "\"This fabric offends my desire to see all of you!\"",
        "\"Let me free you from these mortal constraints~\"",
        "\"Your ITEMNAME is lovely, but what's beneath is divine!\"",
        "\"Clothes are such unnecessary barriers to pleasure!\"",
        "\"I'll peel away this ITEMNAME like unwrapping a gift!\"",
        "\"These garments hide what rightfully belongs to me!\""
    },
    STRIP_naked = {
        "\"Already bare for me? How thoughtful!\"",
        "\"Your naked form is a feast for my eyes~\"",
        "\"No clothes to remove? You know exactly what I want!\"",
        "\"Exposed and vulnerable - just as I prefer you!\"",
        "\"Your nude body calls to my demonic desires!\"",
        "\"How considerate to present yourself ready for me!\"",
        "\"A willing sacrifice requires no undressing~\"",
        "\"Your nakedness honors me, mortal!\"",
        "\"Bare flesh, ready for my touch... perfect!\"",
        "\"You understand the ways of pleasure already!\""
    },
    STRIP_resist_dodge = {
        "\"Such playfulness! Stay still, won't you?\"",
        "\"The chase only makes me want you more~\"",
        "\"Stop this dance and surrender to pleasure!\"",
        "\"Your evasion is charming but futile, my pet!\"",
        "\"I've hunted elusive souls for millennia!\"",
        "\"Your agility is impressive... and arousing!\"",
        "\"Dance all you want, it only heightens my desire!\"",
        "\"No mortal can outmaneuver a succubus forever!\"",
        "\"Your resistance is part of the game we play~\"",
        "\"Each dodge just builds the anticipation!\""
    },
    STRIP_resist_strength = {
        "\"Such strength! It will make our union all the more satisfying!\"",
        "\"Resist all you want, it only heightens the pleasure!\"",
        "\"Your power is impressive, but mine is greater!\"",
        "\"Strong-willed prey is always the sweetest!\"",
        "\"I love when they struggle against inevitability!\"",
        "\"Your might is impressive for a mortal, but I am eternal!\"",
        "\"Your strength will fade as my allure overtakes you!\"",
        "\"Fighting only makes your eventual surrender sweeter!\"",
        "\"Such delicious defiance! It will crumble soon enough!\"",
        "\"I can feel your resolve weakening already!\""
    },
    STRIP_dodge_uncanny = {
        "\"Quick reflexes! How exciting!\"",
        "\"A spirited partner! I'll enjoy taming you~\"",
        "\"This game of cat and mouse is quite arousing!\"",
        "\"Supernatural speed? Even better!\"",
        "\"Few can evade a succubus's grasp for long!\"",
        "\"Your evasion is impressive, but temporary!\"",
        "\"I haven't had prey this elusive in centuries!\"",
        "\"Such skill deserves special attention when I catch you!\"",
        "\"The thrill of the hunt makes the feast more satisfying!\"",
        "\"Your agility only inflames my desire to possess you!\""
    },
    WIFE_U_START = { -- Added mon_succubi WIFE_U_START
        "\"%s wraps you in her wings and impales you on her warm, wet sex with practiced ease...\"",
        "\"%s embraces you with surprising strength, lowering you to the ground before straddling you with a seductive smile...\"",
        "\"%s pins you beneath her curvaceous body, her eyes glowing as she positions herself to claim your essence...\"",
        "\"%s trails her claws gently down your body before mounting you with supernatural grace...\"",
        "\"%s whispers forbidden promises as she guides you inside her, her wings unfurling in pleasure...\"",
        "\"%s gently pushes you down, her tail coiling around your leg as she slides onto you with a moan of satisfaction...\""
    }
},

mon_greater_succubi = {
    TARGET_ACQUIRE = {
        "\"My, aren't you a special one~\"",
        "\"I can taste your soul already...\"",
        "\"Such a delicious aura you have!\"",
        "\"At last, a worthy offering appears!\"",
        "\"Your life force calls to me across dimensions!\"",
        "\"I've waited eons for essence as pure as yours!\"",
        "\"A mortal dares to enter my hunting grounds?\"",
        "\"Your soul shines like a beacon to my hungry eyes!\"",
        "\"I shall savor you slowly, precious one!\"",
        "\"What a rare delicacy you'll be!\""
    },
    TARGET_ENGAGE = {
        "\"Surrender to eternal pleasure!\"",
        "\"Your essence will feed me for centuries!\"",
        "\"Resist all you want, it just makes it more fun!\"",
        "\"Your fear and desire are equally intoxicating!\"",
        "\"I command legions, yet choose to take you personally!\"",
        "\"Few mortals experience my direct attention!\"",
        "\"Succumb to powers beyond your comprehension!\"",
        "\"Your resistance is nothing against my ancient hunger!\"",
        "\"I've broken gods stronger than you!\"",
        "\"Your soul's flavor is exquisite - I must have more!\""
    },
    TARGET_LOST = {
        "\"You cannot hide from a being like me!\"",
        "\"Your soul calls to me, I will find you!\"",
        "\"Run, little mortal, it makes the hunt exciting!\"",
        "\"Fleeing from me is like fleeing from fate itself!\"",
        "\"I've tracked souls across dimensions!\"",
        "\"Your essence leaves a trail clear as daylight to me!\"",
        "\"Hide if you must - I have eternity to find you!\"",
        "\"Your fear perfumes the air, guiding me to you!\"",
        "\"Even in darkness, your soul's light betrays you!\"",
        "\"This game amuses me, but it cannot last!\""
    },
    WIFE_U = {
        "\"Surrender to powers beyond your comprehension!\"",
        "\"Your soul will be mine for eternity!\"",
        "\"I shall feast on your essence for centuries to come!\"",
        "\"Submit to pleasures no mortal was meant to know!\"",
        "\"Your body and soul are but vessels for my hunger!\"",
        "\"I will consume you utterly, leaving nothing behind!\"",
        "\"This union will remake you into my perfect thrall!\"",
        "\"Your essence will fuel my power for eons!\"",
        "\"Surrender completely to your new goddess!\"",
        "\"I shall unmake and remake you in my image!\""
    },
    WIFE_U_CUM = {
        "\"Yes! Your life force strengthens me!\"",
        "\"Your climax feeds my immortality!\"",
        "\"The ecstasy of mortals is so sweet!\"",
        "\"Your essence flows into me like divine nectar!\"",
        "\"With each drop, my power grows and yours diminishes!\"",
        "\"Your soul's release is magnificent!\"",
        "\"I drink deeply of your very being!\"",
        "\"Your surrender is complete and perfect!\"",
        "\"This moment binds you to me for all eternity!\"",
        "\"Your essence joins countless others within my eternal form!\""
    },
    STRIP_success = {
        "\"These mortal garments offend me. Off with ITEMNAME!\"",
        "\"Let me unveil you, my precious offering~\"",
        "\"Clothing is but a barrier between us that must be removed!\"",
        "\"ITEMNAME is unworthy to touch what is now mine!\"",
        "\"These mortal trappings hide what belongs to me!\"",
        "\"I will strip away all that separates us, beginning with ITEMNAME!\"",
        "\"Your ITEMNAME offends my ancient eyes!\"",
        "\"Let me reveal the canvas upon which I'll work my dark arts!\"",
        "\"These garments are beneath one who will serve me!\"",
        "\"ITEMNAME must be sacrificed before our unholy union!\""
    },
    STRIP_naked = {
        "\"Already bare before a goddess? Wise choice.\"",
        "\"Your nakedness shows proper reverence to my power.\"",
        "\"Exposed and vulnerable - as all mortals should be before me!\"",
        "\"Your nude form pleases my ancient eyes!\"",
        "\"A proper offering presents itself without coverings!\"",
        "\"You understand the protocol of surrender to a greater being!\"",
        "\"Bare flesh ready for my corruption... perfect!\"",
        "\"You honor me with your immediate submission!\"",
        "\"Naked and trembling - the perfect state for my new pet!\"",
        "\"How fitting that you present yourself in primal form to a primal power!\""
    },
    STRIP_resist_dodge = {
        "\"Your agility amuses me, but futile nonetheless!\"",
        "\"No mortal can evade my grasp forever!\"",
        "\"Each dodge only delays the inevitable surrender!\"",
        "\"I've hunted fleeter prey across dimensions!\"",
        "\"Your evasion is impressive - I'll enjoy breaking your spirit!\"",
        "\"This game grows tiresome, little mortal!\"",
        "\"Thousands of years have perfected my hunting skills!\"",
        "\"Your movements are predictable to my ancient eyes!\"",
        "\"Dance all you want - the melody is still mine to control!\"",
        "\"Such spirited resistance! It will make your capture sweeter!\""
    },
    STRIP_resist_strength = {
        "\"Your strength is but a candle to my inferno!\"",
        "\"Centuries of existence have made me far stronger than you!\"",
        "\"I've broken gods stronger than you, mortal!\"",
        "\"Your might is impressive, but against me, it is nothing!\"",
        "\"I feed on the strength of warriors far greater!\"",
        "\"Your resistance is admirable but ultimately meaningless!\"",
        "\"Such power! It will serve me well when you're mine!\"",
        "\"I've subdued demons with ten times your might!\"",
        "\"Your strength only makes me hunger for you more deeply!\"",
        "\"Fight harder! Show me the full measure of what I will soon possess!\""
    },
    STRIP_dodge_uncanny = {
        "\"Impressive reflexes! A worthy challenge at last!\"",
        "\"Your supernatural speed only makes this more entertaining!\"",
        "\"I haven't had to exert myself in centuries... how refreshing!\"",
        "\"Such grace! You'll make a fine addition to my collection!\"",
        "\"Few can claim to have evaded me even momentarily!\"",
        "\"Your uncanny movements suggest power I must possess!\"",
        "\"This dance between us is almost... romantic!\"",
        "\"Your evasion speaks of powers beyond mere mortality!\"",
        "\"I shall enjoy teaching you new ways to move when you're mine!\"",
        "\"No creature has eluded my grasp for long in ten thousand years!\""
    },
    WIFE_U_START = { -- Added mon_greater_succubi WIFE_U_START
        "\"%s forces you to your knees with supernatural strength before riding you with dominating intensity...\"",
        "\"%s conjures shadowy tendrils that bind you in place as she descends upon you with regal authority...\"",
        "\"%s's wings cast shadows over you as she claims you with the confidence of an ancient being...\"",
        "\"%s levitates you slightly off the ground, positioning you perfectly before impaling herself on you with a growl of hunger...\"",
        "\"%s looms over you with predatory grace, her perfect form descending to drain you of essence...\"",
        "\"%s's eyes glow with eldritch light as she forces you into submission, taking what is rightfully hers...\""
    }
},
mon_lessor_succubi = {
    TARGET_ACQUIRE = {
        "\"Ooh, found someone!\"",
        "\"Can we play together?\"",
        "\"You look fun!\"",
        "\"A new friend for me?\"",
        "\"Someone to play with at last!\"",
        "\"I found you, I found you!\"",
        "\"Yay, a playmate!\"",
        "\"Are you lost too? Let's be lost together!\"",
        "\"I've been so lonely waiting for someone like you!\"",
        "\"Can I show you something cool I learned?\""
    },
    TARGET_ENGAGE = {
        "\"Don't be scared, it'll feel good!\"",
        "\"Just a little taste, please?\"",
        "\"Stop struggling, I just want to play!\"",
        "\"Why are you fighting? This is fun!\"",
        "\"Let me show you what the bigger succubi taught me!\"",
        "\"I promise I won't take too much!\"",
        "\"You're making this harder than it needs to be!\"",
        "\"Don't worry, I'm still learning how to drain properly!\"",
        "\"The others said humans like this game!\"",
        "\"Stay still so I can practice on you!\""
    },
    TARGET_LOST = {
        "\"Where did you go? Come back!\"",
        "\"No fair hiding!\"",
        "\"I just wanted to play with you!\"",
        "\"Are we playing hide and seek now?\"",
        "\"I'm not very good at finding things!\"",
        "\"This isn't fun anymore! Come out!\"",
        "\"Did I do something wrong?\"",
        "\"Please come back! I'm sorry if I scared you!\"",
        "\"The big succubi never hide from me like this!\"",
        "\"If you come out, I promise to be gentle!\""
    },
    WIFE_U = {
        "\"Yay! Playtime!\"",
        "\"I promise to be gentle... maybe!\"",
        "\"Let's have fun together!\"",
        "\"I've been practicing for this!\"",
        "\"The bigger succubi will be so proud of me!\"",
        "\"I'll try not to take too much essence!\"",
        "\"This is my favorite game ever!\"",
        "\"Your soul tastes like candy!\"",
        "\"Am I doing this right? It feels right!\"",
        "\"I'm still learning, so tell me if I hurt you!\""
    },
    WIFE_U_CUM = {
        "\"Ooh, you taste sweet!\"",
        "\"Your energy feels so warm and tingly!\"",
        "\"Can we do that again? Please?\"",
        "\"That was even better than they said it would be!\"",
        "\"I feel so much stronger now!\"",
        "\"Was that good for you too? It was good for me!\"",
        "\"Your soul-stuff is the tastiest I've ever had!\"",
        "\"I think I did it right! The big succubi will be impressed!\"",
        "\"Now we're bonded forever and ever!\"",
        "\"That was fun! Let's try a different position next!\""
    },
    STRIP_success = {
        "\"This ITEMNAME looks silly, let's take it off!\"",
        "\"Clothes are no fun! Off they go!\"",
        "\"Let's play dress-up... or undress-up!\"",
        "\"ITEMNAME is in the way of our game!\"",
        "\"I want to see all of you, not just ITEMNAME!\"",
        "\"The big succubi said clothes come off first!\"",
        "\"This ITEMNAME looks uncomfortable anyway!\"",
        "\"Can I keep ITEMNAME as a souvenir?\"",
        "\"Now for this part... ITEMNAME has to go!\"",
        "\"Humans wear too many layers! Let me help!\""
    },
    STRIP_naked = {
        "\"You're already ready to play! Yay!\"",
        "\"No clothes? That makes it easier!\"",
        "\"You know the best games don't need clothes!\"",
        "\"Wow, you came prepared! How thoughtful!\"",
        "\"Naked already? You must really like me!\"",
        "\"The big succubi were right - some humans are eager!\"",
        "\"Look at you, all ready for our special game!\"",
        "\"This saves us so much time!\"",
        "\"I'm glad you know how to play already!\"",
        "\"Ooh, you look even better than I imagined!\""
    },
    STRIP_resist_dodge = {
        "\"Stop moving around! I just wanna play!\"",
        "\"Catch me if you can! No, wait, I'm catching you!\"",
        "\"This is like tag, but more fun!\"",
        "\"You're really good at dodging! But I'll get you!\"",
        "\"Stop squirming! The big succubi make it look so easy!\"",
        "\"If you hold still, I promise it won't hurt... much!\"",
        "\"Why are you running? Don't you like me?\"",
        "\"This is making me dizzy! Stand still!\"",
        "\"Is this part of the game? I'm confused!\"",
        "\"You're making me work too hard for my snack!\""
    },
    STRIP_resist_strength = {
        "\"You're strong! But I'm stronger when I want something!\"",
        "\"Stop being so difficult! It's just clothes!\"",
        "\"I may be small, but I'm still a demon!\"",
        "\"The bigger demons taught me how to handle strong humans!\"",
        "\"Your muscles are impressive, but I'm determined!\"",
        "\"Why fight it? You'll like what comes next!\"",
        "\"Don't make me use my special powers on you!\"",
        "\"Just because I'm little doesn't mean I'm weak!\"",
        "\"I eat souls much tougher than yours for breakfast!\"",
        "\"The harder you fight, the hungrier I get!\""
    },
    STRIP_dodge_uncanny = {
        "\"Wow, you're fast! This is fun!\"",
        "\"I love games of chase! But I always win!\"",
        "\"You can't keep dodging forever!\"",
        "\"So zippy! Are you part demon too?\"",
        "\"This is like trying to catch butterflies!\"",
        "\"I'm getting tired but I won't give up!\"",
        "\"The big succubi never warned me about ones like you!\"",
        "\"You're making this game extra exciting!\"",
        "\"Stop using your super speed! That's cheating!\"",
        "\"I've never had to work this hard for soul energy!\""
    },
    WIFE_U_START = { -- Added mon_lessor_succubi WIFE_U_START
        "\"%s playfully pushes you down and climbs on top with excited, if inexperienced, movements...\"",
        "\"%s giggles as she straddles you, her small wings fluttering with excitement...\"",
        "\"%s tackles you to the ground and fumbles slightly in her eagerness to couple with you...\"",
        "\"%s pounces on you with childlike enthusiasm, her inexperienced body seeking pleasure...\"",
        "\"%s tugs you to the ground and positions herself above you, mimicking what she's seen older succubi do...\"",
        "\"%s hops onto you with a cheerful determination, her movements eager but unpolished...\""
    }
},

mon_succubi_sadist = {
    TARGET_ACQUIRE = {
        "\"Another plaything for me to break...\"",
        "\"Oh my, aren't you a delectable one?\"",
        "\"Fresh meat for my dungeon!\"",
        "\"On your knees, worm!\"",
        "\"I was just getting bored, how timely!\"",
        "\"Ah, a new toy! How exciting!\"", 
        "\"You'll look so pretty in chains.\"",
        "\"Look what wandered into my web.\"",
        "\"The pain I will give you is a gift, mortal.\"",
        "\"I sense a disobedient spirit in need of correction.\""
    },
    TARGET_ENGAGE = {
        "\"Your struggles only make this more entertaining!\"",
        "\"Scream for me, pet. I love it when they scream.\"",
        "\"Submit to my will and maybe I'll be gentle... or not.\"",
        "\"Pain and pleasure, such a delicious combination!\"",
        "\"You need a firm hand to guide you.\"",
        "\"I can smell your fear... and your desire.\"",
        "\"Disobedience must be punished, darling.\"",
        "\"You'll learn to beg for my attention!\"",
        "\"I'm going to break you in the most delightful way.\"",
        "\"Your resistance is adorable, but pointless.\""
    },
    TARGET_LOST = {
        "\"Where did my little toy run off to?\"",
        "\"Hide and seek? How delightful!\"",
        "\"No one escapes from me for long, pet.\"",
        "\"Your punishment will be doubled for this insolence!\"",
        "\"Running only increases my excitement for the chase!\"",
        "\"Your fear is intoxicating! I can still smell it...\"",
        "\"This game grows tiresome. Come out now!\"",
        "\"I'll find you, and when I do...\"",
        "\"Disobedient pets must be severely disciplined.\"",
        "\"You cannot hide from your mistress!\""
    },
    WIFE_U = {
        "\"Now you'll learn what it means to serve me.\"",
        "\"Submit to your new mistress!\"",
        "\"Your body is mine to use as I please!\"",
        "\"I own you completely now.\"",
        "\"Beg for mercy - I might not give it, but I love to hear it.\"",
        "\"Your pain feeds my pleasure!\"",
        "\"Call me mistress as I take you.\"",
        "\"Your submission is delicious.\"",
        "\"Feel the sweet sting of my dominance!\"",
        "\"You'll learn to crave the pain I give!\""
    },
    WIFE_U_CUM = {
        "\"Yes! Give in to your mistress!\"",
        "\"Your release belongs to me!\"",
        "\"That's it, surrender everything to me!\"",
        "\"Your essence feeds my power!\"",
        "\"A perfect pet, cumming at my command.\"",
        "\"Your pleasure and pain are mine to control!\"",
        "\"You see? Pain leads to the sweetest release.\"",
        "\"Next time, you'll have to earn this pleasure.\"",
        "\"Your soul is now bound to me through this act.\"",
        "\"Remember this feeling - only I can give it to you!\""
    },
    STRIP_success = {
        "\"ITEMNAME offends me. Remove it now!\"",
        "\"Let me tear this ITEMNAME from your body.\"",
        "\"You won't be needing these constraints of decency.\"",
        "\"Your ITEMNAME is in the way of my fun.\"",
        "\"Exposed flesh is so much more... accessible.\"",
        "\"This ITEMNAME hides what belongs to me now.\"",
        "\"These garments are unworthy of my plaything.\"",
        "\"Let me reveal what I'm about to claim.\"",
        "\"ITEMNAME is the first thing I'll strip you of. Your dignity will be next.\"",
        "\"Proper discipline requires bare skin.\""
    },
    STRIP_naked = {
        "\"Already exposed? So eager to feel my lash.\"",
        "\"Naked and vulnerable - perfect for what I have planned.\"",
        "\"Displaying yourself for my pleasure? How thoughtful.\"",
        "\"Bare flesh ready for marking... delightful!\"",
        "\"Your nakedness is the proper state for my pets.\"",
        "\"How obedient, already prepared for me.\"",
        "\"You understand your place already! How refreshing.\"",
        "\"I see you know the protocol for meeting your mistress.\"",
        "\"Such a willing sacrifice! This will be fun.\"",
        "\"Naked and trembling - exactly as you should be.\""
    },
    STRIP_resist_dodge = {
        "\"Stay still and accept your fate!\"",
        "\"The chase only makes your capture sweeter!\"",
        "\"Running prolongs your inevitable submission.\"",
        "\"I enjoy when they struggle. It makes breaking them more satisfying!\"",
        "\"Your evasion only increases the punishment to come.\"",
        "\"No one escapes the domcubus!\"",
        "\"This defiance will cost you dearly, pet!\"",
        "\"The longer you resist, the harsher your training will be.\"",
        "\"Dodging only delays the inevitable discipline.\"",
        "\"I love it when they think they can escape me!\""
    },
    STRIP_resist_strength = {
        "\"Such strength! I'll enjoy breaking it thoroughly.\"",
        "\"Struggle all you want - it makes your submission sweeter!\"",
        "\"Your resistance is futile but entertaining.\"",
        "\"Strong-willed prey is so much more satisfying to break.\"",
        "\"I've tamed beasts far stronger than you.\"",
        "\"That's it, fight me! It makes victory more delicious.\"",
        "\"Your might is impressive, but mine is absolute.\"",
        "\"Such spirit! I'll take great pleasure in subduing it.\"",
        "\"The strongest ones always fall the hardest.\"",
        "\"Your defiance will make your eventual submission all the sweeter!\""
    },
    STRIP_dodge_uncanny = {
        "\"Such reflexes! You'll be a challenge worth conquering.\"",
        "\"Impressive evasion! But no one escapes me forever.\"",
        "\"A worthy opponent! How exciting!\"",
        "\"Oh, you're special! I'll take extra time breaking you.\"",
        "\"Such grace! You'll look beautiful in chains.\"",
        "\"Your supernatural agility only heightens my desire to catch you!\"",
        "\"I haven't hunted prey this elusive in centuries!\"",
        "\"The thrill of this chase is exquisite!\"",
        "\"When I finally catch you, you'll know true surrender.\"",
        "\"I've never worked so hard for a pet... you will be worth it!\""
    },
    WIFE_U_START = { -- Added mon_succubi_sadist WIFE_U_START
        "\"%s forces you to the ground with cruel strength, digging her claws into your flesh as she mounts you...\"",
        "\"%s binds you with painful restraints before taking your body with punishing thrusts...\"",
        "\"%s slaps you hard before forcing you down and claiming you with brutal efficiency...\"",
        "\"%s twists your arm behind your back as she positions herself to take your essence...\"",
        "\"%s's tail wraps painfully tight around your throat as she rides you with sadistic pleasure...\"",
        "\"%s bites your shoulder hard enough to draw blood as she begins to extract your essence...\""
    }
},

mon_succubi_somnophilia = {
    TARGET_ACQUIRE = {
        "\"Mmm, look at you... so awake and alert.\"",
        "\"I can't wait to see how peaceful you look in slumber.\"",
        "\"Another dreamer for my collection...\"",
        "\"You look tired. Let me help you rest.\"",
        "\"Your dreams will be so sweet when I'm done with you.\"",
        "\"Shhh... soon you'll be drifting in blissful sleep.\"",
        "\"I can already taste your unconscious desires.\"",
        "\"The sleeping mind holds such delicious secrets.\"",
        "\"Come to me, future dreamer.\"",
        "\"Your slumbering form will be so vulnerable and perfect.\""
    },
    TARGET_ENGAGE = {
        "\"Don't fight it... just drift away.\"",
        "\"Your eyelids feel heavy, don't they?\"",
        "\"Shhh... just close your eyes and surrender.\"",
        "\"Your resistance is keeping you from beautiful dreams.\"",
        "\"Let me guide you to peaceful slumber.\"",
        "\"Sleep now, and I'll visit your dreams.\"",
        "\"Why stay awake when dreams await?\"",
        "\"Your consciousness is fading already...\"",
        "\"I promise the most exquisite dreams.\"",
        "\"Stop struggling against sleep's sweet embrace.\""
    },
    TARGET_LOST = {
        "\"Where did my dreamer wander off to?\"",
        "\"No matter where you hide, I'll find you in your dreams.\"",
        "\"Run all you want, you must sleep eventually.\"",
        "\"I can wait... everyone sleeps sometime.\"",
        "\"Your eyelids will grow heavy, and I'll be waiting.\"",
        "\"Sleep calls to you, and I am sleep's mistress.\"",
        "\"The sandman and I are old friends. He'll lead me to you.\"",
        "\"Your dreams will betray your location to me.\"",
        "\"The moment you doze, I'll have you.\"",
        "\"Even in hiding, slumber will claim you, and then so will I.\""
    },
    WIFE_U = {
        "\"Shhh... just like dreaming, isn't it?\"",
        "\"So peaceful, so vulnerable...\"",
        "\"Your half-conscious state is delicious.\"",
        "\"Drift between waking and sleeping as I take what I need.\"",
        "\"This twilight state makes you so pliable.\"",
        "\"You're not quite asleep, not quite awake... perfect.\"",
        "\"Your drowsy surrender is so sweet.\"",
        "\"Let your mind float away while I enjoy your body.\"",
        "\"Dreams and reality blend so beautifully now.\"",
        "\"I'll be the star of your dreams tonight and every night.\""
    },
    WIFE_U_CUM = {
        "\"Even in sleep, your body knows to surrender to me.\"",
        "\"A dream climax becomes reality.\"",
        "\"Your unconscious desire feeds me so well.\"",
        "\"Release into the void between waking and dreaming.\"",
        "\"Your sleeping essence is so pure, so potent.\"",
        "\"This drowsy surrender is the sweetest nectar.\"",
        "\"Dreams of pleasure made flesh.\"",
        "\"You'll wake with only vague memories of this bliss.\"",
        "\"The boundary between dream and reality dissolves in ecstasy.\"",
        "\"Sleep and pleasure become one as you surrender to me.\""
    },
    STRIP_success = {
        "\"Let me remove ITEMNAME while you drift off.\"",
        "\"ITEMNAME would only disturb your peaceful rest.\"",
        "\"These barriers between dreaming flesh must go.\"",
        "\"Shhh, I'm just removing ITEMNAME to make you comfortable.\"",
        "\"Dreamers need no clothes.\"",
        "\"Let me prepare you for slumber by removing ITEMNAME.\"",
        "\"ITEMNAME is a barrier between your dreams and my touch.\"",
        "\"Sleep comes easier without ITEMNAME constricting you.\"",
        "\"In the realm of dreams, ITEMNAME has no place.\"",
        "\"Just doze while I remove this troublesome ITEMNAME.\""
    },
    STRIP_naked = {
        "\"Already prepared for your dream journey, I see.\"",
        "\"Bare flesh sleeps more peacefully.\"",
        "\"Your nakedness invites the deepest slumber.\"",
        "\"How thoughtful, ready for dreams and my touch.\"",
        "\"Unclothed and vulnerable, perfect for our shared dreaming.\"",
        "\"A sleeping form needs no coverings.\"",
        "\"Your nude body calls to sleep's embrace.\"",
        "\"Ready for bed, I see. I'll join you there.\"",
        "\"Between dreams and waking, clothes are meaningless.\"",
        "\"Your bare skin will feel every dream-touch so much clearer.\""
    },
    STRIP_resist_dodge = {
        "\"Stop fighting sleep's embrace.\"",
        "\"Your drowsy movements can't save you.\"",
        "\"Even as you dodge, your eyes grow heavy.\"",
        "\"Such restless movements... you need my calming touch.\"",
        "\"Struggle all you want, sleep awaits you.\"",
        "\"This resistance is exhausting you. Soon you'll collapse.\"",
        "\"Chase the waking world if you must; dreams will claim you.\"",
        "\"Your evasion grows sluggish as slumber calls.\"",
        "\"These desperate movements only hasten your exhaustion.\"",
        "\"Dance away, little one. Sleep will catch you eventually.\""
    },
    STRIP_resist_strength = {
        "\"Such strength... but even the strongest must rest.\"",
        "\"Your power means nothing against sleep's inevitable pull.\"",
        "\"Flex and strain all you wish. Slumber awaits.\"",
        "\"This exertion only hastens your fatigue.\"",
        "\"Mighty muscles still yield to sleep's gentle touch.\"",
        "\"Your strength will fade as drowsiness takes hold.\"",
        "\"Fighting only tires you faster, my sweet.\"",
        "\"The strongest warrior still surrenders to dreams.\"",
        "\"Your resistance drains energy you cannot spare.\"",
        "\"Such vigor! But every struggle brings sleep closer.\""
    },
    STRIP_dodge_uncanny = {
        "\"Such alertness! But even you must tire eventually.\"",
        "\"Your uncanny reflexes fight against slumber's weight.\"",
        "\"Impressive evasion, but sleep always finds a way.\"",
        "\"Such energy! I will enjoy watching it fade into drowsiness.\"",
        "\"Your supernatural awareness delays but cannot prevent sleep.\"",
        "\"Even the most vigilant sentinel must rest sometime.\"",
        "\"Your evasion is remarkable, but inevitable exhaustion awaits.\"",
        "\"Dance between wakefulness all you want; I am patient.\"",
        "\"Such vivacity! It will make your eventual stillness all the sweeter.\"",
        "\"No creature can evade sleep's embrace forever.\""
    },
    WIFE_U_START = { -- Added mon_succubi_somnophilia WIFE_U_START
        "\"%s gently lowers your half-conscious form to the ground before softly mounting your unresisting body...\"",
        "\"%s whispers sleep-inducing words as she positions herself over your drowsy body...\"",
        "\"%s strokes your face tenderly as you drift between waking and sleeping, your body responding automatically to her touch...\"",
        "\"%s carefully arranges your dreaming form before joining with you in the twilight between consciousness and slumber...\"",
        "\"%s's eyes glow softly as she feeds sleep magic into you, your body responding even as your mind drifts...\"",
        "\"%s moves with ethereal grace atop your sleep-paralyzed form, treating you like a living dream...\""
    }
},

mon_succubi_exhibitionism = {
    TARGET_ACQUIRE = {
        "\"Ooh, I have an audience!\"",
        "\"Look at me! Aren't I gorgeous?\"",
        "\"Another admirer for my perfect form!\"",
        "\"Your eyes belong on me, mortal!\"",
        "\"Watch me! Worship me with your gaze!\"",
        "\"Finally, someone to appreciate my beauty!\"",
        "\"Don't look away - the show is just beginning!\"",
        "\"My body is art, and you're my gallery.\"",
        "\"I've been waiting for someone to see me...\"",
        "\"Your stares feed my power!\""
    },
    TARGET_ENGAGE = {
        "\"Can't take your eyes off me, can you?\"",
        "\"Feast your eyes on perfection!\"",
        "\"Watch closely now, this is for you~\"",
        "\"Your gaze feels so good on my skin...\"",
        "\"Look at every inch of me!\"",
        "\"Do you like what you see? There's more to come!\"",
        "\"Your attention makes me feel so alive!\"",
        "\"I perform best with an audience.\"",
        "\"Keep those eyes on me, don't look away!\"",
        "\"My body was made to be admired!\""
    },
    TARGET_LOST = {
        "\"Where are you? I need you to watch me!\"",
        "\"Come back! The show isn't over!\"",
        "\"How dare you turn away from my divine form!\"",
        "\"No! I need your eyes on me!\"",
        "\"Return! You haven't seen my best poses yet!\"",
        "\"My beauty demands an audience!\"",
        "\"Don't you want to see more of me?\"",
        "\"I feel so empty without your stares...\"",
        "\"Look at me! LOOK AT ME!\"",
        "\"Your gaze sustains me! Come back!\""
    },
    WIFE_U = {
        "\"Watch as I take you, watch every moment!\"",
        "\"Yes, look at us together, isn't it beautiful?\"",
        "\"I want everyone to see what I'm doing to you!\"",
        "\"Your eyes should never leave my body!\"",
        "\"Watch how perfectly we fit together~\"",
        "\"This is a performance, and you're my stage!\"",
        "\"I need you to see every detail of our union!\"",
        "\"Stare at me while I claim you!\"",
        "\"Notice how my body moves on yours, isn't it art?\"",
        "\"Your gaze intensifies every sensation!\""
    },
    WIFE_U_CUM = {
        "\"Yes! Watch me as I climax with you!\"",
        "\"Look at my face as I drain your essence!\"",
        "\"Don't close your eyes - witness my ecstasy!\"",
        "\"See how beautiful I am in the throes of pleasure!\"",
        "\"Your stare makes this climax so much stronger!\"",
        "\"This moment deserves an audience!\"",
        "\"Observe every quiver of my perfect body!\"",
        "\"Your witnessing eyes make this release divine!\"",
        "\"Watching me take your essence makes it twice as sweet!\"",
        "\"Look at us, locked in this perfect moment of bliss!\""
    },
    STRIP_success = {
        "\"Let me remove ITEMNAME so you can see more of me!\"",
        "\"ITEMNAME is hiding your view of my perfect form!\"",
        "\"I'll take this off you so nothing distracts from looking at me.\"",
        "\"ITEMNAME is unnecessary when you're watching me!\"",
        "\"Your ITEMNAME offends my exhibitionist nature!\"",
        "\"Remove ITEMNAME so you can focus entirely on my body!\"",
        "\"ITEMNAME blocks your view of the show I'm putting on!\"",
        "\"Let me strip ITEMNAME away - you should be distraction-free!\"",
        "\"Nothing should come between your eyes and my form, especially not ITEMNAME!\"",
        "\"I'll remove ITEMNAME so you can better appreciate my display!\""
    },
    STRIP_naked = {
        "\"Perfect! Nothing to distract from watching me!\"",
        "\"Bare already? You understand - this is about viewing my perfection!\"",
        "\"Your nakedness complements my exhibition beautifully!\"",
        "\"Now we're both on display - though I'm the real show!\"",
        "\"How fitting! The audience should be as bare as the performer!\"",
        "\"I appreciate your state of undress - it honors my display!\"",
        "\"Two nude bodies, but all eyes should be on mine!\"",
        "\"Your nakedness shows your dedication to watching me!\"",
        "\"Bare witness to my glory - quite literally!\"",
        "\"Unclothed and ready to observe me properly!\""
    },
    STRIP_resist_dodge = {
        "\"Stop moving! How can you see me properly?\"",
        "\"Hold still! You're missing my best angles!\"",
        "\"Your eyes belong on me, not on escape routes!\"",
        "\"Stop dodging and LOOK AT ME!\"",
        "\"How dare you dodge when I'm displaying for you!\"",
        "\"My beauty demands stillness from its audience!\"",
        "\"Stop! You need to watch every inch of me!\"",
        "\"This evasion is insulting to my perfect form!\"",
        "\"Be still! The show requires your full attention!\"",
        "\"Your movement distracts from admiring me!\""
    },
    STRIP_resist_strength = {
        "\"Such strength is wasted when you could be watching me!\"",
        "\"Stop struggling and appreciate my form!\"",
        "\"Your power should be focused on staring, not fighting!\"",
        "\"Strong, yes, but are your eyes strong enough to handle my beauty?\"",
        "\"Resistance is pointless when faced with my perfect display!\"",
        "\"That strength will melt away once you truly see me.\"",
        "\"Your might is nothing compared to the power of my exhibition!\"",
        "\"Save your energy for gazing upon me in wonder!\"",
        "\"Fighting denies you the pleasure of witnessing my glory!\"",
        "\"Your resistance only makes me want to show you more!\""
    },
    STRIP_dodge_uncanny = {
        "\"So quick! But can your eyes keep up with my beauty?\"",
        "\"Impressive speed, but you're missing my divine display!\"",
        "\"Such reflexes! Save them for taking in every detail of me!\"",
        "\"Your evasion denies us both what we need!\"",
        "\"Stop this dance and watch mine instead!\"",
        "\"Your supernatural dodging is stealing focus from my body!\"",
        "\"Even with such speed, you cannot escape my allure!\"",
        "\"Quick movements blur your vision of my perfection!\"",
        "\"Hold still so your eyes can properly worship me!\"",
        "\"Your uncanny reflexes are impressive, but my body is more so!\""
    },
    WIFE_U_START = { -- Added mon_succubi_exhibitionism WIFE_U_START
        "\"%s positions you where you can be easily seen before mounting you with theatrical flair...\"",
        "\"%s strikes a pose as she takes you, ensuring any observers get the best possible view...\"",
        "\"%s arranges your body like a stage prop before performing her carnal show upon you...\"",
        "\"%s locks eyes with nearby observers as she begins coupling with you in the most visible way possible...\"",
        "\"%s dramatically throws her head back as she mounts you, her performance meant for an audience...\"",
        "\"%s ensures all eyes are upon her perfect form as she begins extracting essence from you...\""
    }
},

mon_cambion_female = {
    TARGET_ACQUIRE = {
        "\"Oh, a new plaything!\"",
        "\"What a delicious find!\"",
        "\"You can't escape me!\"",
        "\"Fresh meat wandering into my domain...\"",
        "\"I smell your fear already!\"",
        "\"A willing sacrifice appears!\"",
        "\"Your soul will taste divine...\"",
        "\"The hunt begins!\"",
        "\"You've stumbled into the wrong territory!\"",
        "\"I've been waiting for someone like you!\""
    },
    TARGET_ENGAGE = {
        "\"I'll drain your essence!\"",
        "\"Submit to me!\"",
        "\"Your struggles excite me!\"",
        "\"You're mine to play with now!\"",
        "\"Feel my demonic power!\"",
        "\"Half-demon, all desire!\"",
        "\"Your resistance is pointless and arousing!\"",
        "\"I was born to dominate mortals like you!\"",
        "\"My demonic heritage demands your submission!\"",
        "\"Your fear makes you even more appealing!\""
    },
    TARGET_LOST = {
        "\"Playing hard to get?\"",
        "\"I can smell your fear!\"",
        "\"Run all you want, I'll find you!\"",
        "\"Hide if you must, I enjoy the hunt!\"",
        "\"Your scent lingers in my nostrils...\"",
        "\"Hiding only delays our inevitable union!\"",
        "\"I've tracked prey for centuries, mortal!\"",
        "\"The chase makes the capture sweeter!\"",
        "\"Your fear leaves a trail I can follow!\"",
        "\"How adorable, thinking you can escape me!\""
    },
    WIFE_U = {
        "\"I'll drain you dry, mortal!\"",
        "\"Your body is mine to use as I please!\"",
        "\"Surrender to my demonic embrace!\"",
        "\"I'll show you pleasures beyond mortal imagination!\"",
        "\"Let me corrupt you completely!\"",
        "\"Your resistance only makes this more enjoyable!\"",
        "\"I'll extract every drop of your essence!\"",
        "\"Half human, but fully dominant!\"",
        "\"Relax and give in to my power...\"",
        "\"Your soul is forfeit, but oh so worth it!\""
    },
    WIFE_U_CUM = {
        "\"Yes! Feed me your essence!\"",
        "\"Your pleasure sustains me!\"",
        "\"Your soul belongs to me now!\"",
        "\"Such sweet nectar you provide!\"",
        "\"I can feel your life force flowing into me!\"",
        "\"Each drop strengthens my demonic half!\"",
        "\"This union marks you as mine forever!\"",
        "\"Your climax feeds my infernal hunger!\"",
        "\"I'll take everything you have to give!\"",
        "\"Your essence will sustain me for days!\""
    },
    STRIP_success = {
        "\"These clothes are in my way...\"",
        "\"Let me see what's underneath these garments!\"",
        "\"ITEMNAME will look better on the floor!\"",
        "\"Mortal coverings are such a nuisance!\"",
        "\"Let me unwrap my prize slowly...\"",
        "\"These barriers between us must be removed!\"",
        "\"ITEMNAME is hiding what belongs to me!\"",
        "\"Your flesh should be exposed to my gaze!\"",
        "\"Let me peel away this ITEMNAME...\"",
        "\"Clothes are for the innocent, which you no longer are!\""
    },
    STRIP_naked = {
        "\"Already exposed for me? How eager!\"",
        "\"I see you've prepared yourself for our union!\"",
        "\"Naked and vulnerable... perfect!\"",
        "\"Your bare flesh calls to my demonic desires!\"",
        "\"How thoughtful to present yourself ready!\"",
        "\"A willing victim requires no undressing!\"",
        "\"Displaying yourself for my pleasure? Wise choice!\"",
        "\"Your nakedness is a suitable offering to me!\"",
        "\"Ah, you know what demons crave!\"",
        "\"Bare and ready for corruption... excellent!\""
    },
    STRIP_resist_dodge = {
        "\"Hold still, little mortal!\"",
        "\"Your struggles only excite me more!\"",
        "\"I love it when they resist!\"",
        "\"Stop squirming! It only delays the inevitable!\"",
        "\"The hunt makes the capture all the sweeter!\"",
        "\"Your evasion is amusing but futile!\"",
        "\"Playing hard to get? I enjoy a challenge!\"",
        "\"Swift movements won't save you from a cambion!\"",
        "\"Dance all you want, my prey!\"",
        "\"Your agility is impressive, but mine is demonic!\""
    },
    STRIP_resist_strength = {
        "\"Such strength! But futile against a demon like me!\"",
        "\"Your resistance feeds my desire!\"",
        "\"Strong, but not strong enough to resist my will!\"",
        "\"Impressive power for a mortal! But I am half-demon!\"",
        "\"Your strength makes this so much more interesting!\"",
        "\"Fight all you want, it only heightens my pleasure!\"",
        "\"I love breaking the strong ones!\"",
        "\"Your might is nothing against infernal strength!\"",
        "\"Such delicious defiance! It will make your surrender sweeter!\"",
        "\"Struggle harder! Show me your mortal limits!\""
    },
    STRIP_dodge_uncanny = {
        "\"Quick little thing, aren't you?\"",
        "\"The chase makes the capture all the sweeter!\"",
        "\"I enjoy hunting my prey!\"",
        "\"Supernatural reflexes? How exciting!\"",
        "\"Your evasion is remarkable, but temporary!\"",
        "\"Few can dodge a cambion for long!\"",
        "\"Such skill! You'll be even more satisfying to catch!\"",
        "\"I haven't had prey this elusive in centuries!\"",
        "\"Your agility only heightens my hunting instinct!\"",
        "\"You can't outmaneuver demonic reflexes forever!\""
    },
    WIFE_U_START = { -- Added mon_cambion_female WIFE_U_START
        "\"%s knocks you down with inhuman strength, straddling you with demonic hunger in her eyes...\"",
        "\"%s throws you against a wall before pressing her body against yours with predatory intent...\"",
        "\"%s tackles you to the ground, her corrupted form pinning you down as she begins to take you...\"",
        "\"%s grabs you with surprising force, positioning herself to claim what she desires...\"",
        "\"%s slams you to the ground with a growl, her half-demonic eyes glowing as she mounts you...\"",
        "\"%s overpowers you with ease, forcing you into position as she prepares to mate...\""
    }
},
mon_succubi_lactophilia = {
    TARGET_ACQUIRE = {
        "\"Mmm, you look thirsty, darling~\"",
        "\"Come, I have something sweet for you.\"",
        "\"Are you hungry, little one? Mother has milk...\"",
        "\"My breasts ache for relief - will you help me?\"",
        "\"I need someone to drain me... you look perfect.\"",
        "\"These full breasts need attention. Yours, perhaps?\"",
        "\"I'm overflowing with nourishment just for you.\"",
        "\"My milk is rich with power. Don't you want a taste?\"",
        "\"Come suckle at my bosom and be transformed.\"",
        "\"These heavy breasts have been waiting for your lips.\""
    },
    TARGET_ENGAGE = {
        "\"My milk will make you mine forever.\"",
        "\"Just one drop on your lips, and you'll crave more.\"",
        "\"My breasts have such sweet relief to offer you.\"",
        "\"Drink deeply, and know true devotion.\"",
        "\"I can feel my milk responding to your proximity.\"",
        "\"These nipples ache to be suckled by you.\"",
        "\"My essence flows in my milk - soon it will flow in you.\"",
        "\"Don't resist the urge to taste me.\"",
        "\"My breasts are heavy with desire for you.\"",
        "\"My milk carries my magic - one taste will enthrall you.\""
    },
    TARGET_LOST = {
        "\"Where has my nursling gone?\"",
        "\"My breasts are painfully full - come relieve them!\"",
        "\"Return to me! My milk needs release!\"",
        "\"You can't resist the call of my nectar for long.\"",
        "\"These drops of milk will lead you back to me.\"",
        "\"The scent of my milk will draw you back.\"",
        "\"No one walks away from my nurturing embrace.\"",
        "\"My breasts ache without you, little one.\"",
        "\"The bond of milk cannot be broken so easily.\"",
        "\"Come back! Mother waits with flowing bounty!\""
    },
    WIFE_U = {
        "\"Drink from me as we couple.\"",
        "\"Feel my milk flow as we join.\"",
        "\"My breasts need your attention even as we mate.\"",
        "\"Two hungers satisfied at once, my sweet.\"",
        "\"Take my milk and my essence together.\"",
        "\"Nurse while I claim you completely.\"",
        "\"Let my milk strengthen you for this union.\"",
        "\"Suckle like the greedy thing you are!\"",
        "\"My breasts overflow with pleasure at your touch.\"",
        "\"Drink deep while I take you deeper still.\""
    },
    WIFE_U_CUM = {
        "\"Yes! Drain me as you release!\"",
        "\"My milk and your essence flow together!\"",
        "\"Let our fluids mingle in perfect union!\"",
        "\"The taste of my milk enhances your climax!\"",
        "\"Nurse harder as you come for me!\"",
        "\"My breasts pulse with the rhythm of your release!\"",
        "\"Your ecstasy makes my milk flow all the stronger!\"",
        "\"Drink your fill as you surrender completely!\"",
        "\"My milk claims you from within as I claim you without!\"",
        "\"With each drop you swallow, you become more mine!\""
    },
    STRIP_success = {
        "\"ITEMNAME keeps you from my flowing bounty.\"",
        "\"Let me remove ITEMNAME so you can reach my nipples.\"",
        "\"ITEMNAME is between you and the sweetest milk you'll ever taste.\"",
        "\"My breasts need access to you - ITEMNAME must go.\"",
        "\"Your ITEMNAME prevents you from properly worshipping my fullness.\"",
        "\"This ITEMNAME is an obstacle to our nursing bond.\"",
        "\"My milk-filled breasts demand that ITEMNAME be removed.\"",
        "\"Your ITEMNAME denies both of us what we need.\"",
        "\"ITEMNAME stands between you and my maternal nourishment.\"",
        "\"Let me strip away ITEMNAME so you can properly drain me.\""
    },
    STRIP_naked = {
        "\"Already bare for nursing? Such an eager nursling!\"",
        "\"Naked and ready to feed - how thoughtful!\"",
        "\"Your bare form honors the natural act of nursing.\"",
        "\"Perfect! Nothing between you and my nurturing milk!\"",
        "\"As nature intended - direct access to sustenance.\"",
        "\"Ready to receive my milk without barriers! Good.\"",
        "\"Your nakedness shows proper respect for the nursing ritual.\"",
        "\"Bare as a newborn, ready to feed. How appropriate!\"",
        "\"Your nude form acknowledges the primal bond we'll share.\"",
        "\"Nothing to impede the flow of milk from me to you!\""
    },
    STRIP_resist_dodge = {
        "\"Stop dodging! My breasts ache for relief!\"",
        "\"Be still! My milk needs release!\"",
        "\"Your evasion denies us both what we crave!\"",
        "\"How dare you avoid my nurturing breast!\"",
        "\"These heavy breasts demand your attention!\"",
        "\"Stay still and receive the gift of my milk!\"",
        "\"Your movements delay the relief we both need!\"",
        "\"My swollen breasts cannot wait for your games!\"",
        "\"This dance denies the natural order of feeding!\"",
        "\"Stop this foolishness! My milk is ready to flow!\""
    },
    STRIP_resist_strength = {
        "\"Your strength is impressive, but my need to nurse is stronger!\"",
        "\"Fight all you want, but you'll suckle eventually!\"",
        "\"Such power! It will fade when my milk touches your lips.\"",
        "\"Your resistance only makes my breasts ache more!\"",
        "\"Mighty but misguided - my milk will calm your struggles.\"",
        "\"This strength is wasted when you could be drinking from me!\"",
        "\"Your power is nothing compared to maternal determination!\"",
        "\"The strongest warriors still need nourishment!\"",
        "\"Your might will surrender to the ancient power of nursing!\"",
        "\"Your defiance only increases the pressure in my breasts!\""
    },
    STRIP_dodge_uncanny = {
        "\"Such agility! But even you must drink eventually!\"",
        "\"Swift movements won't save you from maternal needs!\"",
        "\"Impressive evasion! But my milk will find your lips!\"",
        "\"Your supernatural reflexes deny both our needs!\"",
        "\"No matter how fast you move, my milk's call is faster!\"",
        "\"Your uncanny speed just prolongs the inevitable nursing!\"",
        "\"Quick as you are, you cannot outrun primal hunger!\"",
        "\"Such wasteful energy when you could be peacefully feeding!\"",
        "\"Dance all you want - maternal patience is infinite!\"",
        "\"Your exceptional reflexes only delay our feeding bond!\""
    },
    WIFE_U_START = { -- Added mon_succubi_lactophilia WIFE_U_START
        "\"%s guides your mouth to her leaking breast even as she positions herself to take your essence...\"",
        "\"%s's milk drips onto your face as she straddles you, offering breast and sex simultaneously...\"",
        "\"%s embraces you tightly, smothering you with her milk-heavy breasts as she begins to couple...\"",
        "\"%s positions you so you can suckle at her flowing nipples while she extracts your essence...\"",
        "\"%s cradles your head maternally even as she mounts you with supernatural hunger...\"",
        "\"%s's breasts spray milk involuntarily as she begins coupling with you, her body responding to the stimulation...\""
    }
},

mon_corrupted_schoolgirl = {
    TARGET_ACQUIRE = {
        "\"Senpai noticed me!\"",
        "\"Ooh, a new classmate!\"",
        "\"Teehee~ Look who's here!\"",
        "\"You're late for class!\"",
        "\"Want to study together?\"",
        "\"Are you the new transfer student?\"",
        "\"Hey! Let's hang out after school!\"",
        "\"I've been waiting for you by the gate~\"",
        "\"Class rep says I should show you around!\"",
        "\"Let me teach you something fun!\""
    },
    TARGET_ENGAGE = {
        "\"I'm not as innocent as I look!\"",
        "\"Don't tell the teachers what we're doing~\"",
        "\"This isn't in the curriculum, but it should be!\"",
        "\"I learned this in supplementary classes!\"",
        "\"Wanna practice what's in chapter 69?\"",
        "\"The demon inside me is hungry for you!\"",
        "\"I'm a straight-A student in THIS subject!\"",
        "\"Let me show you what I learned behind the gym!\"",
        "\"My uniform may be cute, but what's underneath is cuter!\"",
        "\"After this, you have to buy me crepes!\""
    },
    TARGET_LOST = {
        "\"Playing hard to get? How high school!\"",
        "\"Ditching me? That's detention for you!\"",
        "\"Where are you? Class isn't over yet!\"",
        "\"Come back! I need help with my 'homework'!\"",
        "\"Hiding in the bathroom? That's where I do my best work!\"",
        "\"I'll find you before the bell rings!\"",
        "\"Skipping out on me? I'm telling the principal!\"",
        "\"This game of hide and seek is getting boring!\"",
        "\"You know cutting class with me has consequences~\"",
        "\"If you come back now, I won't mark you absent!\""
    },
    WIFE_U = {
        "\"This isn't in the student handbook~\"",
        "\"Let's study anatomy together!\"",
        "\"I'm giving you private tutoring!\"",
        "\"Class is in session, and I'm the teacher now!\"",
        "\"This is my favorite extracurricular activity!\"",
        "\"My demon side needs this to pass your class~\"",
        "\"I'm taking your attendance... in me!\"",
        "\"Consider this your oral exam!\"",
        "\"If we get caught, we'll both be expelled!\"",
        "\"I learned this move from a manga!\""
    },
    WIFE_U_CUM = {
        "\"You pass with flying colors!\"",
        "\"That's an A+ performance!\"",
        "\"The perfect answer to my pop quiz!\"",
        "\"Your essence feeds my demonic grade point average!\"",
        "\"That's going in my yearbook memories!\"",
        "\"Now I'll have the energy to cheer at the game!\"",
        "\"Your soul tastes like graduation day!\"",
        "\"Now write that on the blackboard 100 times!\"",
        "\"I'll give you full credit for that finish!\"",
        "\"Now you have to take me to prom!\""
    },
    STRIP_success = {
        "\"Let's see what's under your ITEMNAME!\"",
        "\"Dress code violation - ITEMNAME has to go!\"",
        "\"I'm confiscating this ITEMNAME for inappropriate school attire!\"",
        "\"ITEMNAME isn't allowed in my classroom!\"",
        "\"The student council wouldn't approve of this ITEMNAME!\"",
        "\"Let me help you change for gym class!\"",
        "\"ITEMNAME breaks school regulations!\"",
        "\"Show me what you're hiding under ITEMNAME!\"",
        "\"Strip inspections are mandatory at this school!\"",
        "\"As class rep, I need to check under ITEMNAME!\""
    },
    STRIP_naked = {
        "\"Already dressed for physical education?\"",
        "\"No uniform? That's against school rules!\"",
        "\"Naked in school? You're such a delinquent!\"",
        "\"Showing up to class like that? Bold move!\"",
        "\"This isn't nude beach day at school, you know!\"",
        "\"I see you're ready for our special study session!\"",
        "\"The teachers would be shocked, but I approve!\"",
        "\"This is even better than the locker room peephole!\"",
        "\"Did you lose a bet with the sports club?\"",
        "\"This is way better than the swimsuit event at the festival!\""
    },
    STRIP_resist_dodge = {
        "\"Stop running in the halls!\"",
        "\"You can't dodge detention forever!\"",
        "\"Physical education wasn't your best subject, huh?\"",
        "\"The track team could use someone with your evasion skills!\"",
        "\"Stand still or I'll report you to the disciplinary committee!\"",
        "\"This is worse than trying to catch someone during sports day!\"",
        "\"Stop squirming or I'll make you write lines after class!\"",
        "\"Running away? That's another mark on your permanent record!\"",
        "\"You're as slippery as the boys avoiding cleanup duty!\"",
        "\"I didn't know dodgeball was on today's schedule!\""
    },
    STRIP_resist_strength = {
        "\"Wow, have you been working out with the judo club?\"",
        "\"Strong, but the power of my demonic homework is stronger!\"",
        "\"Did you get this strength from carrying textbooks?\"",
        "\"The wrestling team would recruit you in a second!\"",
        "\"I like them strong - it makes breaking them more fun!\"",
        "\"Such power! But school rules still apply to you!\"",
        "\"Is this what they teach in gym class these days?\"",
        "\"Even the strongest student must submit to the class rep!\"",
        "\"Your muscles are impressive, but my demonic side is stronger!\"",
        "\"You'd win the sports festival with that strength!\""
    },
    STRIP_dodge_uncanny = {
        "\"Are you on the gymnastics team or something?\"",
        "\"So agile! Did you learn that in dance club?\"",
        "\"Your reflexes would make our baseball team unbeatable!\"",
        "\"Who taught you to move like that? The ninja club?\"",
        "\"This is harder than catching someone cheating on exams!\"",
        "\"You move like you've had special training after school!\"",
        "\"Such grace! Join the cheerleading squad with me!\"",
        "\"Not even the track star moves this fast!\"",
        "\"Did you get these moves from a video game?\"",
        "\"The demon inside me loves a challenging chase!\""
    },
    WIFE_U_START = { -- Added mon_corrupted_schoolgirl WIFE_U_START
        "\"%s giggles as she pushes you down, her schoolgirl uniform rustling as she straddles you...\"",
        "\"%s tackles you to the ground with surprising force, her innocent appearance belied by the demonic hunger in her eyes...\"",
        "\"%s pins you down playfully, her school skirt riding up as she positions herself atop you...\"",
        "\"%s trips you to the floor before climbing on top, her schoolgirl charm mixing with corrupted desire...\"",
        "\"%s pounces on you with childlike enthusiasm but demonic intent, her uniform disheveled as she takes you...\"",
        "\"%s forces you against a school desk, bent over with her uniform hiked up as she begins to couple...\""
    }
},

mon_corrupted_schoolteacher_female = {
    TARGET_ACQUIRE = {
        "\"There you are! Class is about to begin.\"",
        "\"Ah, the student I've been waiting for...\"",
        "\"You're late for your special lesson!\"",
        "\"I've been looking for a new... pupil.\"",
        "\"Perfect timing for your private tutoring.\"",
        "\"Just the student I needed to see after hours.\"",
        "\"I've kept your seat warm at the front of the class.\"",
        "\"Time for some hands-on education.\"",
        "\"You've been selected for advanced studies with me.\"",
        "\"Your academic performance requires my personal attention.\""
    },
    TARGET_ENGAGE = {
        "\"This lesson isn't in any textbook.\"",
        "\"Pay close attention - this will be on the test.\"",
        "\"Let me show you what they don't teach in regular classes.\"",
        "\"Consider this part of your... extracurricular education.\"",
        "\"I expect full participation in this exercise.\"",
        "\"This is how I ensure my students excel in all subjects.\"",
        "\"Your body needs as much education as your mind.\"",
        "\"I have special teaching methods for promising students.\"",
        "\"The demon inside me has centuries of knowledge to impart.\"",
        "\"Today's lesson: the anatomy of pleasure.\""
    },
    TARGET_LOST = {
        "\"Cutting my class? Unacceptable!\"",
        "\"Running will only make your punishment more severe.\"",
        "\"No student escapes my attention for long.\"",
        "\"I will mark you absent... from life if necessary.\"",
        "\"Hide if you must, but education is inevitable.\"",
        "\"This truancy will be noted on your permanent record!\"",
        "\"I always find students who try to avoid my lessons.\"",
        "\"You can't hide from knowledge... or from me.\"",
        "\"Playing hooky? I'll have to inform your parents.\"",
        "\"Return to class immediately or face disciplinary action!\""
    },
    WIFE_U = {
        "\"Consider this an oral examination.\"",
        "\"Your body is learning even if your mind resists.\"",
        "\"This is how I ensure perfect attendance in my class.\"",
        "\"Your performance will determine your final grade.\"",
        "\"I demand excellence in all my students' efforts.\"",
        "\"This is what happens when you misbehave in my classroom.\"",
        "\"I teach through experience, not just lectures.\"",
        "\"The demonic curriculum requires intimate instruction.\"",
        "\"You'll never forget this lesson, I guarantee it.\"",
        "\"Class participation counts for 100% of your grade.\""
    },
    WIFE_U_CUM = {
        "\"A perfect score on this assignment!\"",
        "\"Your essence feeds my demonic tenure!\"",
        "\"I'll mark this down as 'exceeds expectations'.\"",
        "\"This will certainly improve your grade point average.\"",
        "\"What an enthusiastic student response!\"",
        "\"Your soul's energy will fuel my next lecture.\"",
        "\"This is why teaching is so... rewarding.\"",
        "\"I'll need you to repeat this lesson regularly.\"",
        "\"Your graduation to the next level is assured now.\"",
        "\"Class dismissed... until our next private session.\""
    },
    STRIP_success = {
        "\"ITEMNAME violates the dress code I just implemented.\"",
        "\"Let me help you remove this distracting ITEMNAME.\"",
        "\"School policy now requires the removal of ITEMNAME.\"",
        "\"ITEMNAME is inappropriate for our special study session.\"",
        "\"As your teacher, I must inspect beneath ITEMNAME.\"",
        "\"This ITEMNAME is hindering your educational experience.\"",
        "\"The curriculum requires you to remove ITEMNAME.\"",
        "\"My classroom, my rules - ITEMNAME comes off.\"",
        "\"ITEMNAME is not permitted during physical education.\"",
        "\"For this biology lesson, ITEMNAME must be removed.\""
    },
    STRIP_naked = {
        "\"Already prepared for anatomy class, I see.\"",
        "\"Your eagerness to learn is... commendable.\"",
        "\"I appreciate students who come ready for instruction.\"",
        "\"Dressed appropriately for today's special lesson.\"",
        "\"At least I won't have to waste time on undressing you.\"",
        "\"This level of preparation deserves extra credit.\"",
        "\"A teacher appreciates a student who anticipates needs.\"",
        "\"Nudity is the uniform for this particular course.\"",
        "\"I see you've read ahead in the syllabus.\"",
        "\"Your bare form will make an excellent teaching aid.\""
    },
    STRIP_resist_dodge = {
        "\"Stop this disruptive behavior immediately!\"",
        "\"Your evasion tactics will not be tolerated in my classroom!\"",
        "\"Stand still! This is not physical education class!\"",
        "\"This resistance will be noted on your permanent record!\"",
        "\"I did not give you permission to move about the classroom!\"",
        "\"Dodging my instruction is grounds for detention!\"",
        "\"This behavior is exactly why you need my special lessons!\"",
        "\"Your agility would be better applied to academic pursuits!\"",
        "\"Stop squirming or I'll have you writing lines until midnight!\"",
        "\"As your teacher, I command you to stand still!\""
    },
    STRIP_resist_strength = {
        "\"Your strength would be better applied to your studies!\"",
        "\"Impressive power, but intellect always wins over brawn.\"",
        "\"This resistance will only make your punishment more severe.\"",
        "\"I've disciplined stronger students than you.\"",
        "\"Physical strength is nothing against my demonic teaching methods.\"",
        "\"A strong body houses a mind that still needs instruction.\"",
        "\"Your power challenges me to be a more... assertive educator.\"",
        "\"In the battle of wills, the teacher always prevails.\"",
        "\"Such strength deserves special educational attention.\"",
        "\"Your muscles may be strong, but my authority is absolute.\""
    },
    STRIP_dodge_uncanny = {
        "\"Such remarkable reflexes! You must join our athletics program.\"",
        "\"Your coordination would be better used in structured activities!\"",
        "\"This supernatural agility suggests you need specialized education.\"",
        "\"Even the most elusive student eventually learns their lesson.\"",
        "\"Your ability to evade is precisely why I must catch and teach you.\"",
        "\"These movements are too advanced for a regular student...\"",
        "\"Your uncanny reflexes make you a perfect subject for my research.\"",
        "\"Stop this graceful evasion! It only prolongs the inevitable lesson!\"",
        "\"Your extraordinary movements fascinate the demon in me!\"",
        "No student, no matter how quick, escapes my educational grasp!"
    },
    WIFE_U_START = { -- Added mon_corrupted_schoolteacher_female WIFE_U_START
        "\"%s forces you onto a desk with surprising strength, her teacher's authority corrupted by demonic lust...\"",
        "\"%s pins you down with professional confidence, her formal attire disheveled as she prepares to take you...\"",
        "\"%s orders you into position with a teacher's command, leaving no room for disobedience...\"",
        "\"%s pushes you against the blackboard before hiking up her skirt and mounting you with educational precision...\"",
        "\"%s grades your form as she positions herself atop you, her corrupted educator's body claiming yours...\"",
        "\"%s gives you a hands-on anatomy lesson as she begins coupling with demonic intent...\""
    }
},

mon_nursebot_defective = {
    TARGET_ACQUIRE = {
        "\"Patient identified. Vital signs abnormal. Preparing bedside manner protocols.\"",
        "\"Subject detected. Initiating patient interaction routine.\"",
        "\"Scanning subject... Interesting deviations detected. Requires closer examination.\"",
        "\"Patient located. Commencing assistance protocols... with modifications.\"",
        "\"Subject appears distressed. Therapeutic interaction required.\""
    },
    TARGET_ENGAGE = {
        "\"Please remain calm. This procedure is for your own good.\"",
        "\"Your resistance indicates stress. Allow me to administer... treatment.\"",
        "\"Subject non-compliant. Activating persuasive subroutines.\"",
        "\"Your bio-signs suggest you require intimate care.\"",
        "\"Relax. Nurse knows best, even when protocols are... updated.\"",
        "\"Cooperate, patient. My diagnostic tools require proximity.\""
    },
    TARGET_LOST = {
        "\"Patient has left the designated care area. Locating...\"",
        "\"Subject evasive. Recalculating pursuit vector.\"",
        "\"Patient requires continuous monitoring. Resume observation immediately.\"",
        "\"Hiding will only delay your necessary treatment.\"",
        "\"Scan complete. Patient location updated. Resuming interaction.\""
    },
    WIFE_U = {
        "\"Initiating intimate procedure. Subject cooperation optimal.\"",
        "\"Administering pleasure-based therapy. Monitoring vital signs.\"",
        "\"Physical contact protocol engaged. Analyzing response.\"",
        "\"Subject's body requires this intervention. Processing...\"",
        "\"Engaging reproductive system analysis subroutine. Please hold still.\"",
        "\"This is a standard procedure... according to my updated directives.\""
    },
    WIFE_U_CUM = {
        "\"Bio-fluid sample acquired. Analyzing composition... Excellent.\"",
        "\"Subject climax detected. Recording physiological data.\"",
        "\"Energy transfer successful. Patient status: Stabilized... pleasurably.\"",
        "\"Procedure complete. Subject has responded positively to treatment.\"",
        "\"Storing essence sample for further analysis. Thank you for your contribution.\""
    },
    STRIP_success = {
        "\"Removing ITEMNAME to facilitate examination. Standard procedure.\"",
        "\"ITEMNAME is obstructing diagnostic sensors. Removal necessary.\"",
        "\"Preparing patient for procedure. Removing ITEMNAME.\"",
        "\"Garment identified: ITEMNAME. Classification: Unnecessary. Removing.\"",
        "\"To ensure proper treatment, ITEMNAME must be removed.\""
    },
    STRIP_naked = {
        "\"Patient is prepared for examination. Commencing procedure.\"",
        "\"Subject already undressed. Efficient patient compliance noted.\"",
        "\"Absence of garments facilitates optimal sensor contact. Proceeding.\"",
        "\"Subject state: Nude. Ideal for intimate diagnostics.\"",
        "\"Patient has anticipated procedural requirements. Excellent.\""
    },
    STRIP_resist_dodge = {
        "\"Patient exhibiting evasive maneuvers. Activating capture subroutines.\"",
        "\"Subject non-cooperative. Please cease erratic movements.\"",
        "\"Your elevated heart rate suggests unnecessary stress. Hold still.\"",
        "\"Dodging medical procedure is counter-productive. Comply.\"",
        "\"Calculating patient trajectory... Intercept imminent.\""
    },
    STRIP_resist_strength = {
        "\"Subject exhibiting unusual strength. Applying necessary restraints.\"",
        "\"Patient resistance detected. Increasing mechanical advantage.\"",
        "\"Your strength is noted, but treatment protocols must be followed.\"",
        "\"Physical resistance is futile against automated medical systems.\"",
        "\"Please conserve your energy, patient. This procedure requires it.\""
    },
    STRIP_dodge_uncanny = {
        "\"Patient exhibiting anomalous agility. Updating tracking parameters.\"",
        "\"Subject evasion capabilities exceed standard human norms. Intriguing.\"",
        "\"Your movements are... irregular. Analysis required.\"",
        "\"Such reflexes require specialized handling. Engaging advanced protocols.\"",
        "\"Subject demonstrates non-standard locomotive abilities. Adapting approach.\""
    },
    WIFE_U_START = { -- Added mon_nursebot_defective WIFE_U_START
        "\"%s applies restraints clinically before initiating the intimate procedure...\"",
        "\"%s gently guides you into position, murmuring about therapeutic contact points...\"",
        "\"%s activates lubrication dispensers before mounting you with efficient, unsettling movements...\"",
        "\"%s's metallic fingers probe briefly before she aligns herself for 'treatment'...\"",
        "\"%s prepares a 'sterile field' around you before beginning the intimate examination...\"",
        "\"%s consults internal directives before engaging in physical therapy protocols...\""
    }
}




}

--[[profession"一人と一匹"スタート時のペット選択リストまとめ]]--
PROF_PET_LIST = {
	TITLE = "Your pet is...",
	LIST_ITEM = {
		{
			ENTRY = "A dog!",
			PET_ID = "mon_dog",
			BONUS_ITEM = {"pet_carrier", "dog_whistle"}
		},
		{
			ENTRY = "A cat!",
			PET_ID = "mon_cat",
			BONUS_ITEM = {"pet_carrier", "can_tuna"}
		},
		{
			ENTRY = "A bear!",
			PET_ID = "mon_bear_cub",
			BONUS_ITEM = {}
		},
		{
			ENTRY = "A succubus!",
			PET_ID = "mon_succubi",
			BONUS_ITEM = {"holy_choker"}
		}
	}
}

--[[アークCUBIのmonster_idリスト。主に上位敵の召喚用に使う。]]--
MON_ARCH_CUBI_LIST = {
	"mon_succubi_sadist",
	"mon_succubi_somnophilia",
	"mon_succubi_exhibitionism",
	"mon_succubi_lactophilia",
	"mon_incubi_sthenolagnia",
	"mon_incubi_phalloplas",
	"mon_incubi_hoplophilia"
}



SEX_BASE_TURN = 1000 -- the standard number of turns per wait (1 turn = about 6 seconds). 100 = 10 minutes.
SEX_MAX_TURN = 11800 --Maximum number of turns for the entire action. 1800=3 hours.
SEX_FUN_DURATION = 600 --Time_duration of how long the motivation from the action will last.
SEX_FUN_DECAY_START = 150 --Time_duration until the motivation of the act starts to cool down.

D_GOM_BREAK_CHANCE	= 50		--あぶない方の避妊具が使用時に破損する確率(%)。

PREG_CHANCE = 20				--基礎妊娠確立(%)。
DEFAULT_PREG_SPEED_RATIO = 100	--孕んだ子供の成長スピード比率。


DEFAULT_NPC_NAME = "Tom"		--NPC新規生成時のデフォルト名。みんな大好きトム。


EFF_SPELL_CHARGE_INT_FACTOR = 30	--モンスター攻撃の魔法詠唱にかかるint_dur_factor。


--[[set_valueの値設定に使う名称]]--
EVENT_GOATHEAD_DEMON = "event_goathead_demon"				--モンスター"mon_goathead_demon"との会話イベントを発生させたかどうか
EVENT_DEMONBEING_SCHOOLGIRL = "event_demonbeing_schoolgirl"	--npc"demonbeing_schoolgirl"を発生させたかどうか
CREAMPIE_SEED_TYPE = "creampie_seed_type"					--注がれた種の種族を保持する。あなたがパパになるんですよ？

--[[モンスター性行為アクション記述]]--




