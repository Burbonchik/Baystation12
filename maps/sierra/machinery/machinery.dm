//Shouldn't be a lot in here, only sierra versions of existing machines that need a different access req or something along those lines.

/obj/machinery/drone_fabricator/sierra
	fabricator_tag = "NES Sierra Maintenance"

/obj/machinery/drone_fabricator/sierra/adv
	name = "advanced drone fabricator"
	fabricator_tag = "SFV Arrow Maintenance"
	drone_type = /mob/living/silicon/robot/drone/construction

//telecommunications gubbins for sierra-specific networks

/obj/machinery/telecomms/hub/preset
	id = "Hub"
	network = "tcommsat"
	autolinkers = list("hub", "relay", "c_relay", "s_relay", "m_relay", "r_relay", "b_relay", "1_relay", "2_relay", "3_relay", "4_relay", "5_relay", "s_relay", "science", "medical",
	"supply", "service", "common", "command", "engineering", "security", "exploration", "unused",
 	"receiverA", "broadcasterA")

/obj/machinery/telecomms/receiver/preset_right
	freq_listening = list(AI_FREQ, SCI_FREQ, MED_FREQ, SUP_FREQ, SRV_FREQ, COMM_FREQ, ENG_FREQ, SEC_FREQ, ENT_FREQ, EXP_FREQ)

/obj/machinery/telecomms/bus/preset_two
	freq_listening = list(SUP_FREQ, SRV_FREQ, EXP_FREQ)
	autolinkers = list("processor2", "supply", "service", "exploration", "unused")

/obj/machinery/telecomms/server/presets/service
	id = "Service and Exploration Server"
	freq_listening = list(SRV_FREQ, EXP_FREQ)
	channel_tags = list(
		list(SRV_FREQ, "Service", COMMS_COLOR_SERVICE),
		list(EXP_FREQ, "Exploration", COMMS_COLOR_EXPLORER)
	)
	autolinkers = list("service", "exploration")

/obj/machinery/telecomms/server/presets/exploration
	id = "Utility Server"
	freq_listening = list(EXP_FREQ)
	channel_tags = list(list(EXP_FREQ, "Exploration", COMMS_COLOR_EXPLORER))
	autolinkers = list("Exploration")

// Suit cyclers and storage
/obj/machinery/suit_cycler/exploration
	name = "Exploration suit cycler"
	model_text = "Exploration"
	req_access = list(access_explorer)
	available_modifications = list(/decl/item_modifier/space_suit/explorer)

/obj/machinery/suit_cycler/pilot
	req_access = list(access_explorer) //because unathi version of expeditonary suit it shit

/obj/machinery/suit_storage_unit/explorer
	name = "Exploration Voidsuit Storage Unit"
	suit = /obj/item/clothing/suit/space/void/exploration
	helmet = /obj/item/clothing/head/helmet/space/void/exploration
	boots = /obj/item/clothing/shoes/magboots
	tank = /obj/item/tank/oxygen
	mask = /obj/item/clothing/mask/gas/half
	req_access = list(access_explorer)
	islocked = 1
	mycolour = "#9966ff"

/obj/machinery/suit_storage_unit/pilot
	name = "Expeditionary Pilot Voidsuit Storage Unit"
	suit = /obj/item/clothing/suit/space/void/pilot
	helmet = /obj/item/clothing/head/helmet/space/void/pilot
	boots = /obj/item/clothing/shoes/magboots
	tank = /obj/item/tank/oxygen
	mask = /obj/item/clothing/mask/breath
	req_access = list(access_explorer, access_expedition_shuttle_helm)
	islocked = 1
	mycolour = "#990000"

/obj/machinery/suit_storage_unit/standard_unit
	islocked = 0

/obj/machinery/photocopier/faxmachine/centcomm
	req_access = list(access_cent_general)
	department = "Office of Civil Investigation and Enforcement"

/obj/machinery/photocopier/faxmachine/centcomm/Initialize()
	. = ..()
	destination = pick(GLOB.alldepartments)
	department = "[GLOB.using_map.boss_name]"

/obj/machinery/photocopier/faxmachine/centcomm/attack_hand(mob/user as mob)
	user.set_machine(src)
	var/dat = "Fax Machine<BR>"
	var/scan_name
	if(scan)
		scan_name = scan.name
	else
		scan_name = "--------"
	dat += "Confirm Identity: <a href='byond://?src=\ref[src];scan=1'>[scan_name]</a><br>"
	if(authenticated)
		dat += "<a href='byond://?src=\ref[src];logout=1'>{Log Out}</a>"
	else
		dat += "<a href='byond://?src=\ref[src];auth=1'>{Log In}</a>"
	dat += "<hr>"
	if(authenticated)
		dat += "<b>Logged in to:</b> [GLOB.using_map.boss_name] Quantum Entanglement Network<br><br>"
		if(copyitem)
			dat += "<a href='byond://?src=\ref[src];remove=1'>Remove Item</a><br><br>"
			dat += "<a href='byond://?src=\ref[src];send=1'>Send via NONSECURE connection</a><br>"
			dat += "<b>Currently sending:</b> [copyitem.name]<br>"
			dat += "<b>Sending to:</b> <a href='byond://?src=\ref[src];dept=1'>[destination]</a><br>"
		else
			dat += "Please insert paper to send via NONSECURE connection.<br><br>"
			dat += "<b>Sending to:</b> <a href='byond://?src=\ref[src];dept=1'>[destination]</a><br>"
			dat += "<a href='byond://?src=\ref[src];secsend=1'>Create and send message via SECURE connection</a><br>"
	else
		dat += "Proper authentication is required to use this device.<br><br>"
		if(copyitem)
			dat += "<a href ='byond://?src=\ref[src];remove=1'>Remove Item</a><br>"
	show_browser(user, dat, "window=copier")
	onclose(user, "copier")
	return

/obj/machinery/photocopier/faxmachine/centcomm/Topic(href, href_list)
	var/mob/user = usr
	if(href_list["send"])
		if(copyitem)
			if (destination in admin_departments)
				visible_message("[src] beeps, \"It's looks stupid...\"")
			else
				sendfax(destination)

	else if(href_list["remove"])
		if(copyitem)
			user.put_in_hands(copyitem)
			to_chat(user, "<span class='notice'>You take \the [copyitem] out of \the [src].</span>")
			copyitem = null
			updateUsrDialog()

	if(href_list["secsend"])	//May cause some bad situations...
		if (!destination)
			visible_message("[src] beeps, \"No departament selected.\"")
			return
		var/kek = user.client.holder
		if (!istype(kek,/datum/admins))
			visible_message("[src] beeps, \"DNA check failed! Heads was warned!\"")
			log_fax("[key_name(user)] found admin fax machine and use it without admin rights!")
			for(var/client/C in GLOB.admins)
				if((R_INVESTIGATE) & C.holder.rights)
					to_chat(C, "<span class='log_message'><span class='prefix'>FAX LOG:</span>[key_name(user)] found admin fax machine and use it without admin rights!([admin_jump_link(user, src)]))</span>")
			return
		var/exit
		for(var/obj/machinery/photocopier/faxmachine/sendto in GLOB.allfaxes)
			if(sendto.department == destination)
				exit = sendto
		var/replyorigin = input(user, "Please specify who the fax is coming from", "Origin") as text|null
		var/obj/item/paper/admin/P = new /obj/item/paper/admin(user) //hopefully the null loc won't cause trouble for us
		P.admindatum = user.client.holder
		P.origin = replyorigin
		P.destination = exit
		P.adminbrowse()
		visible_message("[src] beeps, \"Setting up secure channel...\"")

	if(href_list["scan"])
		if (scan)
			if(ishuman(user))
				user.put_in_hands(scan)
			else
				scan.dropInto(loc)
			scan = null
		else
			var/obj/item/I = user.get_active_hand()
			if (istype(I, /obj/item/card/id) && user.unEquip(I, src))
				scan = I
		authenticated = 0

	if(href_list["dept"])
		var/lastdestination = destination
		destination = input(usr, "Which department?", "Choose a department") as null|anything in GLOB.alldepartments
		if(!destination)
			destination = lastdestination

	if(href_list["auth"])
		if(!authenticated && scan && check_access(scan))
			authenticated = 1

	if(href_list["logout"])
		authenticated = 0
	updateUsrDialog()

//bridge space turrets

/obj/machinery/turretid/sierra_bridge
	lethal = 1
	check_arrest = 1	//checks if the perp is set to arrest
	check_records = 1	//checks if a security record exists at all
	check_weapons = 1	//checks if it can shoot people that have a weapon they aren't authorized to have
	check_access = 1	//if this is active, the turret shoots everything that does not meet the access requirements
	req_access = list(access_bridge)

// lockdown b_doors
/obj/machinery/door/blast/regular/lockdown
	name = "Security Lockdown"
	desc = "That looks like it doesn't open easily. \
	But that one has NFC sign. May be my ID can help?"
	req_access = list(list(access_sec_doors, access_engine, access_medical))
	begins_closed = FALSE
	icon_state = "pdoor0"
	// Дальше только ад.
	min_force = 50
	maxhealth = 5000

// Как я и обещал, бронестворки можно емагать.
/obj/machinery/door/blast/regular/lockdown/emag_act(remaining_charges)
	. = ..(remaining_charges, TRUE)
	if(.)
		// Если уж емагаются, то все сразу
		for(var/obj/machinery/door/blast/regular/lockdown/door in SSmachines.machinery)
			if(door.id_tag == id_tag && door.density && door.operable())
				INVOKE_ASYNC(door, /obj/machinery/door/proc/do_animate, "emag")
				addtimer(CALLBACK(door, /obj/machinery/door/proc/emag_open), 6)

/obj/machinery/door/blast/regular/lockdown/attackby(obj/item/C as obj, mob/user as mob)
	. = ..(C, user)
	if(isid(C) || istype(C, /obj/item/modular_computer/pda))
		if(allowed(user))
			for(var/obj/machinery/door/blast/regular/lockdown/door in SSmachines.machinery)
				if(door.id_tag == id_tag)
					INVOKE_ASYNC(door, /obj/machinery/door/proc/open)
		return

/obj/machinery/door/blast/regular/lockdown/attack_ai()
	for(var/obj/machinery/door/blast/regular/lockdown/door in SSmachines.machinery)
		if(door.id_tag == id_tag)
			if(door.density)
				INVOKE_ASYNC(door, /obj/machinery/door/proc/open)
			else
				INVOKE_ASYNC(door, /obj/machinery/door/proc/close)

/obj/machinery/door/blast/regular/lockdown/AIMiddleClick(var/mob/AI)
	return attack_ai(AI)

/obj/machinery/door/blast/regular/lockdown/BorgCtrlClick(var/mob/AI)
	return AIMiddleClick(AI)

/turf/simulated/AIMiddleClick(var/mob/AI)
	. = ..()
	for(var/obj/machinery/door/blast/regular/lockdown/door in contents)
		door.AIMiddleClick(AI)

/turf/simulated/BorgCtrlClick(var/mob/AI)
	. = ..()
	for(var/obj/machinery/door/blast/regular/lockdown/door in contents)
		door.AIMiddleClick(AI)

/obj/structure/window/AIMiddleClick(var/mob/AI)
	. = ..()
	var/turf/turf = get_turf(src)
	for(var/obj/machinery/door/blast/regular/lockdown/door in turf.contents)
		door.AIMiddleClick(AI)

/obj/structure/window/BorgCtrlClick(var/mob/AI)
	. = ..()
	for(var/obj/machinery/door/blast/regular/lockdown/door in contents)
		door.AIMiddleClick(AI)
