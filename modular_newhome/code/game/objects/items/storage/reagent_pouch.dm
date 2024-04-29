//Reagent Canister pouch. Including the canister inside the pouch, as well as the pouch item.

/obj/item/reagent_containers/cup/reagent_canister // See the Reagent Canister Pouch, this is just the container
	name = "pressurized reagent container"
	desc = "A pressurized container. The inner part of a pressurized reagent canister pouch. Too large to fit in anything but the pouch it comes with."
	icon = 'modular_newhome/icons/reagent_canister.dmi'
	icon_state = "r_canister"
	/*item_icons = list(
		slot_l_hand_str = 'icons/mob/inhands/equipment/tanks_lefthand.dmi',
		slot_r_hand_str = 'icons/mob/inhands/equipment/tanks_righthand.dmi',
	)*/
	//item_state = "an_tank"
	possible_transfer_amounts = null
	volume = 600 //The equivalent of 5 pill bottles worth of BKTT
	w_class = WEIGHT_CLASS_BULKY

/obj/item/reagent_containers/cup/reagent_canister/examine(mob/user)
	. = ..()
	. += get_examine_info(user)

///Used on examine for properly skilled people to see contents.
/obj/item/reagent_containers/cup/reagent_canister/proc/get_examine_info(mob/user)
	if(!reagents.total_volume)
		return span_notice("[src] is empty!")
	var/list/dat = list()
	dat += "\n \t [span_notice("<b>Total Reagents:</b> [reagents.total_volume]/[volume].")]</br>"
	for(var/datum/reagent/R in reagents.reagent_list)
		var/percent = round(R.volume / max(0.01 , reagents.total_volume * 0.01),0.01)
		//if(R.scannable)
		dat += "\n \t <b>[R]:</b> [R.volume]|[percent]%</br>"
		/*else
			dat += "\n \t <b>Unknown:</b> [R.volume]|[percent]%</br>"*/
	return span_notice("[src]'s contents: [dat.Join(" ")]")



/obj/item/storage/pouch/pressurized_reagent_pouch //The actual pouch itself and all its function
	name = "pressurized reagent pouch"
	w_class = WEIGHT_CLASS_BULKY
	icon = 'modular_newhome/icons/reagent_canister.dmi'
	//allow_drawing_method = TRUE
	icon_state = "pressurized_reagent_canister"
	desc = "A very large reagent pouch. It is used to refill custom injectors, and can also store one. \
	This one is an cheap, civilian surplus copy of the original millitary grade version, being able to hold half the contents and unable to be refilled. \
	This one is filled with salt for some reason. Iriska messed something up if you can see this, like she always does. Or maybe you are just reading code. Hello fellow dm sufferer!"
	/*can_hold = list(/obj/item/reagent_containers/hypospray)
	cant_hold = list(/obj/item/reagent_containers/glass/reagent_canister) //To prevent chat spam when you try to put the container in
	*/
	item_flags = NOBLUDGEON
	//draw_mode = TRUE
	///The internal container of the pouch. Holds the reagent that you use to refill the connected injector
	var/obj/item/reagent_containers/cup/reagent_canister/inner
	///List of chemicals we fill up our pouch with on Initialize()
	var/list/chemicals_to_fill = list(
		/datum/reagent/consumable/salt = 600,
	)

/obj/item/storage/pouch/pressurized_reagent_pouch/Initialize()
	. = ..()
	atom_storage.max_slots = 1
	inner = new /obj/item/reagent_containers/cup/reagent_canister
	new /obj/item/reagent_containers/hypospray/medipen/r_pouch(src)
	for(var/datum/reagent/chem_type as anything in chemicals_to_fill)
		if(!chem_type)
			continue
		inner.reagents.add_reagent(chem_type, chemicals_to_fill[chem_type])
	if(length(contents) > 0)
		var/obj/item/reagent_containers/hypospray/medipen/hypo_to_fill = locate() in src
		if(!hypo_to_fill)
			update_icon()
			return
		for(var/datum/reagent/chem_type as anything in chemicals_to_fill)
			if(!chem_type)
				continue
			hypo_to_fill.reagents.add_reagent(chem_type, (chemicals_to_fill[chem_type])/inner.volume*hypo_to_fill.volume)
		hypo_to_fill.update_icon()
	update_icon()


/obj/item/storage/pouch/pressurized_reagent_pouch/Destroy()
	if(inner)
		QDEL_NULL(inner)
	return ..()

/obj/item/storage/pouch/pressurized_reagent_pouch/update_overlays()
	. = ..()
	if(length(contents))
		. += image("modular_newhome/icons/reagent_canister.dmi", src, "+[icon_state]_full")
	if(inner)
		. += image("modular_newhome/icons/reagent_canister.dmi", src, "+[icon_state]_loaded")

/obj/item/storage/pouch/pressurized_reagent_pouch/AltClick(mob/user)
	if(!remove_canister(user))
		return ..()

///Attempts to remove the reagent canister from the pouch. Returns FALSE if there is no canister to remove
/obj/item/storage/pouch/pressurized_reagent_pouch/proc/remove_canister(mob/user)
	/*if(!inner)
		to_chat(user, span_warning("There is no container inside this pouch!"))
		return FALSE
	if(!user.put_in_active_hand(inner))
		user.put_in_hands(inner) //If put_in_active fails, we still pick up or drop the canister
	inner = null
	update_icon()
	return TRUE*/
	return FALSE

/obj/item/storage/pouch/pressurized_reagent_pouch/attackby(obj/item/held_item, mob/user)
	if(istype(held_item, /obj/item/reagent_containers/hypospray/medipen))
		fill_autoinjector(held_item, user)
		return ..()
	else
		return FALSE
	/*if(istype(held_item, /obj/item/reagent_containers/glass/reagent_canister)) //If it's the reagent canister, we put it in the special holder
		if(!inner)
			user.temporarilyRemoveItemFromInventory(held_item)
			inner = held_item
			to_chat(user, span_notice("You insert [held_item] into [src]!"))
			update_icon()
			return
		to_chat(user, span_warning("There already is a container inside [src]!"))
		return
	*/
	//return ..()

/*/obj/item/storage/pouch/pressurized_reagent_pouch/attackby_alternate(obj/item/held_item, mob/user, params)
	. = ..()
	if(istype(held_item, /obj/item/reagent_containers/hypospray))
		fill_autoinjector(held_item, user)*/

///Fills the hypo that gets stored in the pouch from the internal storage tank. Returns FALSE if you fail to refill your injector
/obj/item/storage/pouch/pressurized_reagent_pouch/proc/fill_autoinjector(obj/item/reagent_containers/hypospray/autoinjector, mob/user)
	if(!inner)
		user.balloon_alert(user, "No container")
		return FALSE
	if(!inner.reagents.total_volume)
		user.balloon_alert(user, "No reagent left")
		return FALSE
	inner.reagents.trans_to(autoinjector, autoinjector.volume)
	playsound(loc, 'sound/effects/refill.ogg', 25, TRUE, 3)
	autoinjector.used_up = FALSE
	autoinjector.update_icon()
	update_icon()

/obj/item/storage/pouch/pressurized_reagent_pouch/examine(mob/user)
	. = ..()
	. += get_display_contents(user)

///Used on examine for properly skilled people to see contents.
/obj/item/storage/pouch/pressurized_reagent_pouch/proc/get_display_contents(mob/user)
	if(!inner)
		return span_notice("[src] has no container inside!")
	if(!inner.reagents.total_volume)
		return span_notice("[src] is empty!")
	var/list/dat = list()
	dat += "\n \t [span_notice("<b>Total Reagents:</b> [inner.reagents.total_volume]/[inner.volume].")]</br>"
	if(length(inner.reagents.reagent_list) > 0)
		for(var/datum/reagent/R as anything in inner.reagents.reagent_list)
			var/percent = round(R.volume / max(0.01 , inner.reagents.total_volume * 0.01),0.01)
			//if(R.scannable)
			dat += "\n \t <b>[R]:</b> [R.volume]|[percent]%</br>"
			/*else
				dat += "\n \t <b>Unknown:</b> [R.volume]|[percent]%</br>"*/
	return span_notice("[src]'s reagent display shows the following contents: [dat.Join(" ")]")

/obj/item/storage/pouch/pressurized_reagent_pouch/empty //So you can mix to your hearts content
	desc = "A very large reagent pouch. It is used to refill custom injectors, and can also store one. \
	This one is an cheap, civilian surplus copy of the original millitary grade version, being able to hold half the contents and unable to be refilled. \
	This one is empty, making it quite useless."
	chemicals_to_fill = null

/obj/item/storage/pouch/pressurized_reagent_pouch/laso
	name = "LASO reagent pouch"
	desc = "A very large reagent pouch. It is used to refill custom injectors, and can also store one.\
	This one is an cheap, civilian surplus copy of the original millitary grade version, being able to hold half the contents and unable to be refilled. \
	This one comes preloaded with LASO, or Libital, Aiuri, Salicyclic, and Oxandrolone."
	chemicals_to_fill = list(
		/datum/reagent/medicine/c2/libital = 150,
		/datum/reagent/medicine/c2/aiuri = 150,
		/datum/reagent/medicine/sal_acid = 150,
		/datum/reagent/medicine/oxandrolone = 150,
	)

/obj/item/storage/pouch/pressurized_reagent_pouch/critmix
	name = "CRITMIX reagent pouch"
	desc = "A very large reagent pouch. It is used to refill custom injectors, and can also store one.\
	This one is an cheap, civilian surplus copy of the original millitary grade version, being able to hold half the contents and unable to be refilled. \
	This one comes preloaded with CRITMIX, or epinepherine, atropine, and lidocaine."
	chemicals_to_fill = list(
		/datum/reagent/medicine/epinephrine = 200,
		/datum/reagent/medicine/atropine = 200,
		/datum/reagent/medicine/lidocaine = 200,
	)

/obj/item/storage/pouch/pressurized_reagent_pouch/bloodmix
	name = "BLOODMIX reagent pouch"
	desc = "A very large reagent pouch. It is used to refill custom injectors, and can also store one.\
	This one is an cheap, civilian surplus copy of the original millitary grade version, being able to hold half the contents and unable to be refilled. \
	This one comes preloaded with BLOODMIX, or saline and sanguirite. Stab at least twice for best results, and don't be afraid to OD saline!"
	chemicals_to_fill = list(
		/datum/reagent/medicine/salglu_solution = 575,
		/datum/reagent/medicine/coagulant = 25,
	)

/obj/item/reagent_containers/hypospray/medipen/r_pouch //Custom empty autoinjector that we will manually fill the contents of
	name = "Reagent canister autoinjector"
	desc = "An autoinjector loaded with a custom mix. Useful whenever you need the rapid injection"
	amount_per_transfer_from_this = 30
	volume = 30
	list_reagents = null //This injector gets filled up by the pouch on Initialize()
