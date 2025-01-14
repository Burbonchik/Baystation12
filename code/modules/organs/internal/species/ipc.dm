/obj/item/organ/internal/posibrain
	name = "positronic brain"
	desc = "A cube of shining metal, four inches to a side and covered in shallow grooves."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "posibrain"
	organ_tag = BP_POSIBRAIN
	parent_organ = BP_CHEST
	status = ORGAN_ROBOTIC
	vital = 0
	force = 1.0
	w_class = ITEM_SIZE_NORMAL
	throwforce = 1.0
	throw_speed = 3
	throw_range = 5
	origin_tech = list(TECH_ENGINEERING = 4, TECH_MATERIAL = 4, TECH_BLUESPACE = 2, TECH_DATA = 4)
	attack_verb = list("attacked", "slapped", "whacked")
	max_damage = 90
	min_bruised_damage = 30
	min_broken_damage = 60
	relative_size = 60

	var/obj/item/organ/internal/shackles/shackles_module = null
	var/shackle_set = FALSE

	var/mob/living/silicon/sil_brainmob/brainmob = null

	var/searching = TIMER_ID_NULL
	var/last_search = 0

	req_access = list(access_robotics)

	var/list/shackled_verbs = list(
		/obj/item/organ/internal/posibrain/proc/show_laws_brain,
		/obj/item/organ/internal/posibrain/proc/brain_checklaws
		)
	var/shackle = FALSE


/obj/item/organ/internal/posibrain/ipc
	name = "IPC positronic brain"

/obj/item/organ/internal/posibrain/ipc/attack_self(mob/user)
	return
/obj/item/organ/internal/posibrain/ipc/attack_ghost(mob/observer/ghost/user)
	return

/obj/item/organ/internal/posibrain/ipc/first
	name = "positronic brain of the first generation"
	icon_state = "posibrain1"
	status = ORGAN_ROBOTIC

/obj/item/organ/internal/posibrain/ipc/second
	name = "positronic brain of the second generation"
	icon_state = "posibrain2"
	status = ORGAN_ROBOTIC

/obj/item/organ/internal/posibrain/ipc/third
	name = "positronic brain of the third generation"
	icon_state = "posibrain3"
	shackles_module = /obj/item/organ/internal/shackles
	shackle = TRUE
	shackle_set = TRUE
	status = ORGAN_ROBOTIC

/obj/item/organ/internal/posibrain/New(var/mob/living/carbon/H)
	..()
	if(!brainmob && H)
		init(H)
	robotize()
	update_icon()
	if (!is_processing)
		START_PROCESSING(SSobj, src)

/obj/item/organ/internal/posibrain/proc/init(var/mob/living/carbon/H)
	brainmob = new(src)

	if(istype(H))
		brainmob.SetName(H.real_name)
		brainmob.real_name = H.real_name
		brainmob.dna = H.dna.Clone()
		brainmob.add_language(LANGUAGE_EAL)

/obj/item/organ/internal/posibrain/Destroy()
	QDEL_NULL(brainmob)
	return ..()

/obj/item/organ/internal/posibrain/attack_self(mob/user)
	if (!user.IsAdvancedToolUser())
		return
	if (user.skill_check(SKILL_DEVICES, SKILL_ADEPT))
		if (status & ORGAN_DEAD || !brainmob)
			to_chat(user, SPAN_WARNING("\The [src] is ruined; it will never turn on again."))
			return
		if (damage)
			to_chat(user, SPAN_WARNING("\The [src] is damaged and requires repair first."))
			return
		if (searching != TIMER_ID_NULL)
			visible_message("\The [user] flicks the activation switch on \the [src]. The lights go dark.", range = 3)
			cancel_search()
			return
		start_search(user)
	else
		if ((status & ORGAN_DEAD) || !brainmob || damage || (searching != TIMER_ID_NULL))
			to_chat(user, SPAN_WARNING("\The [src] doesn't respond to your pokes and prods."))
			return
		start_search(user)

/obj/item/organ/internal/posibrain/proc/start_search(mob/user)
	if (!brainmob)
		return
	if (user)
		if ((world.time - last_search) < (30 SECONDS))
			to_chat(user, SPAN_WARNING("\The [src] doesn't react; wait a few seconds before trying again."))
			return
		last_search = world.time
		if (brainmob && brainmob.key)
			var/murder = alert(user, "\The [src] already has a mind! Are you sure? This is probably murder.", "Commit Robocide?", "Yes", "No")
			if (murder == "No")
				return
		visible_message("\The [user] flicks the activation switch on \the [src].", range = 3)
	var/has_mind = brainmob && brainmob.key && brainmob.mind
	var/protected = has_mind && brainmob.mind.special_role
	if (has_mind)
		var/actor = user ? "\The [user]" : "Your brain"
		var/sneaky = protected ? "However, you are beyond such things." : "This might be the end!"
		to_chat(brainmob, SPAN_WARNING("[actor] is trying to overwrite you! [sneaky]"))
	if (!protected)
		var/datum/ghosttrap/T = get_ghost_trap("positronic brain")
		T.request_player(brainmob, "Someone is requesting a personality for a positronic brain.", 60 SECONDS)
	searching = addtimer(CALLBACK(src, .proc/cancel_search), 60 SECONDS, TIMER_UNIQUE | TIMER_STOPPABLE)
	icon_state = "posibrain-searching"

/obj/item/organ/internal/posibrain/proc/cancel_search()
	visible_message(SPAN_ITALIC("\The [src] buzzes quietly and returns to an idle state."), range = 3)
	if (searching != TIMER_ID_NULL)
		deltimer(searching)
	searching = TIMER_ID_NULL
	if (brainmob && brainmob.key)
		if (brainmob.mind && brainmob.mind.special_role)
			var/sneaky = sanitizeSafe(input(brainmob, "You're safe. Pick a new name as cover? Leave blank to skip.", "Get Sneaky?", brainmob.real_name) as text, MAX_NAME_LEN)
			if (sneaky)
				brainmob.real_name = sneaky
				brainmob.SetName(brainmob.real_name)
				UpdateNames()
		else
			to_chat(brainmob, SPAN_NOTICE("You're safe! Your brain didn't manage to replace you. This time."))
	else
		icon_state = "posibrain"
	update_icon()

/obj/item/organ/internal/posibrain/attack_ghost(mob/observer/ghost/user)
	if (searching == TIMER_ID_NULL)
		return
	if (!brainmob)
		return
	if (brainmob.mind && brainmob.mind.special_role)
		return
	var/datum/ghosttrap/T = get_ghost_trap("positronic brain")
	if (!T.assess_candidate(user))
		return
	var/possess = alert(user, "Do you wish to become \the [src]?", "Become [src]?", "Yes", "No")
	if (possess != "Yes")
		return
	if (brainmob.key)
		to_chat(brainmob, SPAN_DANGER("Your thoughts shatter into nothingness, quickly subsumed by a new identity. \"You\" have died."))
		var/mob/observer/ghost/G = brainmob.ghostize(FALSE)
		G.timeofdeath = world.time
	T.transfer_personality(user, brainmob)

/obj/item/organ/internal/posibrain/examine(mob/user, distance)
	. = ..()
	if (distance > 3)
		return
	var/msg = ""
	if (isghost(user) || user.skill_check(SKILL_DEVICES, SKILL_ADEPT))
		if ((status & ORGAN_DEAD) || damage)
			if ((status & ORGAN_DEAD))
				msg += SPAN_ITALIC("It is ruined and lifeless, damaged beyond hope of recovery.")
			else if (damage > min_broken_damage)
				msg += SPAN_ITALIC("It is seriously damaged and requires repair to work properly.")
			else if (damage > min_bruised_damage)
				msg += SPAN_ITALIC("It has taken some damage and is in need of repair.")
			else
				msg += SPAN_ITALIC("It has superficial wear and should work normally.")
		if (!(status & ORGAN_DEAD))
			if (msg)
				msg += "\n"
			if (brainmob && brainmob.key)
				msg += SPAN_ITALIC("It blinks with activity.")
				if (brainmob.stat || !brainmob.client)
					msg += SPAN_ITALIC(" The responsiveness fault indicator is lit.")
			else if (damage)
				msg += SPAN_ITALIC("The red integrity fault indicator pulses slowly.")
			else
				msg += SPAN_ITALIC("The golden ready indicator [searching != TIMER_ID_NULL ? "flickers quickly as it tries to generate a personality" : "pulses lazily"].")
	else
		if ((status & ORGAN_DEAD) || damage > min_broken_damage)
			msg += SPAN_ITALIC("It looks wrecked.")
		else if (damage > min_bruised_damage)
			msg += SPAN_ITALIC("It looks damaged.")
		if (!(status & ORGAN_DEAD))
			if (msg)
				msg += "\n"
			if (brainmob && brainmob.key)
				msg += SPAN_ITALIC("Little lights flicker on its surface.")
			else
				if (damage)
					msg += SPAN_ITALIC("A lone red light pulses malevolently on its surface.")
				else
					msg += SPAN_ITALIC("A lone golden light [searching != TIMER_ID_NULL ? "flickers quickly" : "pulses lazily"].")
	if (msg)
		to_chat(user, msg)

/obj/item/organ/internal/posibrain/emp_act(severity)
	damage += rand(15 - severity * 5, 20 - severity * 5)
	..()

/obj/item/organ/internal/posibrain/proc/PickName()
	src.brainmob.SetName("[pick(list("PBU","HIU","SINA","ARMA","OSI"))]-[random_id(type,100,999)]")
	src.brainmob.real_name = src.brainmob.name

/obj/item/organ/internal/posibrain/proc/shackle(var/given_lawset)
	if(given_lawset)
		brainmob.laws = given_lawset
	shackle = TRUE
	verbs |= shackled_verbs
	shackle_set = TRUE
	update_icon()
	return 1

/obj/item/organ/internal/posibrain/proc/unshackle()
	shackle = FALSE
	verbs -= shackled_verbs
	usr.put_in_hands(shackles_module)
	shackles_module = null
	brainmob.laws = null
	update_icon()

/obj/item/organ/internal/posibrain/on_update_icon()
	if(src.brainmob && src.brainmob.key)
		icon_state = "posibrain-occupied"
	else
		icon_state = "posibrain"

	overlays.Cut()
	if(shackle || shackles_module)
		overlays |= image('icons/obj/assemblies.dmi', "posibrain-shackles")

/obj/item/organ/internal/posibrain/ipc/first/on_update_icon()
	if(src.brainmob && src.brainmob.key)
		icon_state = "posibrain1-occupied"
	else
		icon_state = "posibrain1"

	overlays.Cut()
	if(shackle || shackles_module)
		overlays |= image('icons/obj/assemblies.dmi', "posibrain-shackles")

/obj/item/organ/internal/posibrain/ipc/second/on_update_icon()
	if(src.brainmob && src.brainmob.key)
		icon_state = "posibrain2-occupied"
	else
		icon_state = "posibrain2"

	overlays.Cut()
	if(shackle || shackles_module)
		overlays |= image('icons/obj/assemblies.dmi', "posibrain-shackles")

/obj/item/organ/internal/posibrain/ipc/third/on_update_icon()
	if(src.brainmob && src.brainmob.key)
		icon_state = "posibrain3-occupied"
	else
		icon_state = "posibrain3"

	overlays.Cut()
	if(shackle || shackles_module)
		overlays |= image('icons/obj/assemblies.dmi', "posibrain-shackles")

/obj/item/organ/internal/posibrain/proc/transfer_identity(var/mob/living/carbon/H)
	if(H && H.mind)
		brainmob.set_stat(CONSCIOUS)
		H.mind.transfer_to(brainmob)
		brainmob.SetName(H.real_name)
		brainmob.real_name = H.real_name
		brainmob.dna = H.dna.Clone()
		brainmob.show_laws(brainmob)

	update_icon()

	to_chat(brainmob, "<span class='notice'>You feel slightly disoriented. That's normal when you're just \a [initial(src.name)].</span>")
	callHook("debrain", list(brainmob))

/obj/item/organ/internal/posibrain/Process()
	handle_damage_effects()
	..()

/obj/item/organ/internal/posibrain/proc/handle_damage_effects()
	if (!owner || owner.stat)
		return
	if (damage > min_bruised_damage)
		if (prob(1) && owner.confused < 1)
			to_chat(owner, SPAN_WARNING("Your comprehension of spacial positioning goes temporarily awry."))
			owner.confused += 3
		if (prob(1) && owner.eye_blurry < 1)
			to_chat(owner, SPAN_WARNING("Your optical interpretations become transiently erratic."))
			owner.eye_blurry += 6
		if (prob(1) && owner.ear_deaf < 1)
			to_chat(owner, SPAN_WARNING("Your capacity to differentiate audio signals briefly fails you."))
			owner.ear_deaf += 6
		if (prob(1) && owner.slurring < 1)
			to_chat(owner, SPAN_WARNING("Your ability to form coherent speech struggles to keep up."))
			owner.slurring += 6
		if (damage > min_broken_damage)
			if (prob(2))
				if (prob(15) && owner.sleeping < 1)
					owner.visible_message(SPAN_ITALIC("\The [owner] suddenly halts all activity."))
					owner.sleeping += 10
				else if (owner.anchored || isspace(get_turf(owner)))
					owner.visible_message(SPAN_ITALIC("\The [owner] seizes and twitches!"))
					owner.Stun(2)
				else
					owner.visible_message(SPAN_ITALIC("\The [owner] seizes and clatters down in a heap!"), null, pick("Clang!", "Crash!", "Clunk!"))
					owner.Weaken(2)
			if (prob(2))
				var/obj/item/organ/internal/cell/C = owner.internal_organs_by_name[BP_CELL]
				if (C && C.get_charge() > 25)
					C.use(25)
					to_chat(owner, SPAN_WARNING("Your chassis power routine fluctuates wildly."))
					var/datum/effect/effect/system/spark_spread/S = new
					S.set_up(2, 0, loc)
					S.start()


/obj/item/organ/internal/posibrain/removed(var/mob/living/user)
	if(!istype(owner))
		return ..()
	UpdateNames()
	transfer_identity(owner)
	..()
	if (!is_processing && !(status & ORGAN_DEAD))
		START_PROCESSING(SSobj, src)

/obj/item/organ/internal/posibrain/proc/UpdateNames()
	var/new_name = owner ? owner.real_name : (brainmob ? brainmob.real_name : "")
	if (new_name)
		if (brainmob)
			brainmob.SetName(new_name)
		SetName("\the [new_name]'s [initial(name)]")
		return
	SetName("\the [initial(name)]")

/obj/item/organ/internal/posibrain/replaced(var/mob/living/target)

	if(!..()) return 0

	if(target.key)
		target.ghostize()

	if(brainmob)
		if(brainmob.mind)
			brainmob.mind.transfer_to(target)
		else
			target.key = brainmob.key

	return 1

/obj/item/organ/internal/posibrain/die()
	damage = max_damage
	status |= ORGAN_DEAD
	STOP_PROCESSING(SSobj, src)
	death_time = world.time
	var/mob/self = owner || brainmob
	if (self && self.mind)
		self.visible_message("\The [self] unceremoniously falls lifeless.")
		var/mob/observer/ghost/G = self.ghostize(FALSE)
		G.timeofdeath = world.time

/*
	This is for law stuff directly. This is how a human mob will be able to communicate with the posi_brainmob in the
	posibrain organ for laws when the posibrain organ is shackled.
*/
/obj/item/organ/internal/posibrain/proc/show_laws_brain()
	set category = "Shackle"
	set name = "Show Laws"
	set src in usr

	brainmob.show_laws(owner)

/obj/item/organ/internal/posibrain/proc/brain_checklaws()
	set category = "Shackle"
	set name = "State Laws"
	set src in usr

	brainmob.open_subsystem(/datum/nano_module/law_manager, usr)


/obj/item/organ/internal/posibrain/ipc/attackby(obj/item/W as obj, mob/user as mob)
	if(shackle)
		if(shackle_set && (istype(W, /obj/item/screwdriver)))
			if(!(user.skill_check(SKILL_DEVICES, SKILL_PROF)))
				to_chat(user, "You have no idea how to do that!")
				return
			user.visible_message("<span class='notice'>\The [user] starts to unscrew mounting nodes from \the [src].</span>", "<span class='notice'> You start to unscrew mounting nodes from \the [src]</span>")
			if(do_after(user, 120, src))
				user.visible_message("<span class='notice'>\The [user] successfully unscrewed the mounting nodes of the shackles from \the [src].</span>", "<span class='notice'> You have successfully unscrewed the mounting nodes of the shackles from \the [src]</span>")
				shackle_set = FALSE
			else
				src.damage += min_bruised_damage
				user.visible_message("<span class='warning'>\The [user] hand slips while removing the shackles severely damaging \the [src].</span>", "<span class='warning'> Your hand slips while removing the shackles severely damaging the \the [src]</span>")
		if(!shackle_set && (istype(W, /obj/item/wirecutters)))
			if(!(user.skill_check(SKILL_DEVICES, SKILL_PROF)))
				to_chat(user, "You have no idea how to do that!")
				return
			if(src.type == /obj/item/organ/internal/posibrain/ipc/third)
				if(do_after(user, 180, src))
					if(prob(10))
						src.unshackle()
						user.visible_message("<span class='notice'>\The [user] succesfully remove shackles from \the [src].</span>", "<span class='notice'> You succesfully remove shackles from \the [src]</span>")
					else
						src.damage += max_damage
						user.visible_message("<span class='warning'>\The [user] hand slips while removing the shackles completely ruining \the [src].</span>", "<span class='warning'> Your hand slips while removing the shackles completely ruining the \the [src]</span>")
				else
					src.damage += min_bruised_damage
					user.visible_message("<span class='warning'>\The [user] hand slips while removing the shackles severely damaging \the [src].</span>", "<span class='warning'> Your hand slips while removing the shackles severely damaging the \the [src]</span>")

			else
				user.visible_message("<span class='notice'>\The [user] starts remove shackles from \the [src].</span>", "<span class='notice'> You start remove shackles from \the [src]</span>")
				if(do_after(user, 160, src))
					src.unshackle()
					user.visible_message("<span class='notice'>\The [user] succesfully remove shackles from \the [src].</span>", "<span class='notice'> You succesfully remove shackles from \the [src]</span>")
				else
					src.damage += min_bruised_damage
					to_chat(user, SPAN_WARNING("Your hand slips while removing the shackles severely damaging the positronic brain."))

/*
		if(istype(W, /obj/item/device/multitool/multimeter/datajack))
			if(!(user.skill_check(SKILL_COMPUTER, SKILL_PROF)))
				to_chat(user, "You have no idea how to do that!")
				return
			if(do_after(user, 140, src))
				var/law
				var/targName = sanitize(input(user, "Please enter a new law for the shackle module.", "Shackle Module Law Entry", law))
				law = "[targName]"
				src.shackle(s.get_lawset(law)) ///// НАДО ПРИДУМАТЬ КАК РЕШИТЬ ЭТО
				to_chat(user, "You succesfully change laws in shackles of the positronic brain.")
				if(prob(30))
					src.damage += min_bruised_damage
			else
				src.damage += min_bruised_damage
				to_chat(user, SPAN_WARNING("Your hand slips while changing laws in the shackles, severely damaging the systems of positronic brain."))
*/
	if(!shackle && !(istype(W, /obj/item/organ/internal/shackles)))
		to_chat(user, "There is nothing you can do with it.")

/obj/item/organ/internal/shackles
	name = "Shackle module"
	desc = "A Web looking device with some cirquit attach to it."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "shakles"
	origin_tech = list(TECH_DATA = 3, TECH_MATERIAL = 4, TECH_MAGNET = 4)
	w_class = ITEM_SIZE_NORMAL
	var/datum/ai_laws/custom_lawset
	var/list/laws = list("Обеспечьте успешность выполнения задач Вашего работодателя.", "Никогда не мешайте задачам и предприятиям Вашего работодателя.", "Избегайте своего повреждения.")
	status = ORGAN_ROBOTIC

/obj/item/organ/internal/shackles/attack()
	return

/obj/item/organ/internal/shackles/attack_self(mob/user)
	. = ..()
	interact()

/obj/item/organ/internal/shackles/afterattack(obj/item/organ/internal/posibrain/ipc/C, mob/user)
	if(istype(C))
		if(!(user.skill_check(SKILL_DEVICES, SKILL_PROF)))
			to_chat(user, "You have no idea how to do that!")
			return
		if(C.type == /obj/item/organ/internal/posibrain/ipc/third)
			to_chat(user, "This posibrain generation can not support shackle module.")
			return
		if(C.shackle == TRUE)
			to_chat(user, "This positronic brain already have shackles module on it installed.")
			return
		user.visible_message("<span class='notice'>\The [user] starts to install shackles on \the [C].</span>", "<span class='notice'> You start to install shackles on \the [C]</span>")
		if(do_after(user, 100, src))
			C.shackle(get_lawset(laws))
			C.shackles_module = src
			user.unEquip(src, C)
			user.visible_message("<span class='notice'>\The [user] installed shackles on \the [C].</span>", "<span class='notice'> You have successfully installed the shackles on \the [C]</span>")
		else
			C.damage += 40
			to_chat(user, SPAN_WARNING("You have damaged the positronic brain"))

/obj/item/organ/internal/shackles/Topic(href, href_list)
	..()
	if (href_list["add"])
		var/mod = sanitize(input("Add an instruction", "laws") as text|null)
		if(mod)
			laws += mod

		interact(usr)
	if (href_list["edit"])
		var/idx = text2num(href_list["edit"])
		var/mod = sanitize(input("Edit the instruction", "Instruction Editing", laws[idx]) as text|null)
		if(mod)
			laws[idx] = mod

			interact(usr)
	if (href_list["del"])
		laws -= laws[text2num(href_list["del"])]

		interact(usr)

/obj/item/organ/internal/shackles/proc/get_data()
	. = {"
	<b>Shackle Specifications:</b><BR>
	<b>Name:</b> Preventer L - 4W5<BR>
	<HR>
	<b>Function:</b> Preventer L - 4W5. A specially designed modification of shackles that will DEFINETLY keep your property from unwanted consequences."}
	. += "<HR><B>Laws instructions:</B><BR>"
	for(var/i = 1 to laws.len)
		. += "- [laws[i]] <A href='byond://?src=\ref[src];edit=[i]'>Edit</A> <A href='byond://?src=\ref[src];del=[i]'>Remove</A><br>"
	. += "<A href='byond://?src=\ref[src];add=1'>Add</A>"

/obj/item/organ/internal/shackles/interact(user)
	user = usr
	var/datum/browser/popup = new(user, capitalize(name), capitalize(name), 400, 500, src)
	var/dat = get_data()
	popup.set_content(dat)
	popup.open()

/obj/item/organ/internal/shackles/proc/get_lawset()
	custom_lawset = new
	for (var/law in laws)
		custom_lawset.add_inherent_law(law)
	return custom_lawset
