/*
 * Copyright (C) 2014 Atlas of Living Australia
 * All Rights Reserved.
 *
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 */

package au.org.ala.pigeonhole

import au.org.ala.pigeonhole.command.Sighting
import grails.converters.JSON
import org.codehaus.groovy.grails.web.json.JSONArray
import org.codehaus.groovy.grails.web.json.JSONObject
import org.springframework.web.servlet.ModelAndView

class SubmitSightingController {
    def httpWebService, authService, ecodataService, bieService

    def index(String id) {
        log.debug "ID = ${id} || ${params}"
        log.debug "getTaxonForGuid = ${getTaxonForGuid(id)}"
        [
                taxon: getTaxonForGuid(id),
                coordinateSources: grailsApplication.config.coordinates.sources,
                speciesGroupsMap: bieService.getSpeciesGroupsMap(),
                user:authService.userDetails()
        ]
    }

    def edit(String id, String guid) {
        log.debug "id = ${id} || guid = ${guid} || params = ${params}"
        Sighting sighting = ecodataService.getSighting(id)

        if (sighting.error) {
            //flash.message = sighting.error
            render view: "index", model: [
                    sighting: sighting,
                    user:authService.userDetails()
            ]
        } else {
            log.debug "EDIT - taxonConceptID = ${sighting.taxonConceptID} || getTaxonForGuid(sighting.taxonConceptID)"
            log.debug "EDIT - sighting = ${(sighting as JSON).toString(true)}"

            // guid not provided in URL so lookup guid first
            if (!guid) {
                guid = getGuidForName(sighting.scientificName)
            }

            // ModelAndView used to support "chain" with model (work around)
            return new ModelAndView('index', [
                    sighting: sighting,
                    taxon: getTaxonForGuid(guid),
                    coordinateSources: grailsApplication.config.coordinates.sources,
                    speciesGroupsMap: bieService.getSpeciesGroupsMap(),
                    user:authService.userDetails()
            ])
        }
    }

    def upload(Sighting sighting) {
        log.debug "upload params: ${(params as JSON).toString(true)}"
        log.debug "upload sighting: ${(sighting as JSON).toString(true)}"
        def userId = authService.userId ?: 99999
        def userDisplayName = authService.displayName ?: ""
        def debug = grailsApplication.config.submit.debug;

        if (!sighting.userId) {
            // edits will already have user info - don't clobber
            sighting.userId = userId
            sighting.userDisplayName = userDisplayName
        } else

        if (!sighting.validate()) {
            sighting.errors.allErrors.each {
                log.warn "upload validation error: ${it}"
            }
            log.debug "chaining - sighting = ${sighting}"
            flash.message = "There was a problem with one or more fields, please fix these errors (in red)"

            if (sighting.occurrenceID) {
                chain(action: "edit", id: "${sighting.occurrenceID?:''}", model: [sighting: sighting])
            } else {
                chain(action: "index", id: "${sighting.taxonConceptID?:''}", model: [sighting: sighting])
            }
        } else if (debug) {
            // testing without ecodata running
            String sj = (sighting as JSON).toString(true)
            flash.message = "You sighting was successfully (dummy) submitted." +
                    "<br><code>${sj}</code>"
            redirect(uri:'/sightings/user')
        } else {
            // POST sighting to ecodata
            JSONObject result = ecodataService.submitSighting(sighting)

            if (result.error) {
                // ecodata returned an error
                flash.message = "There was a problem submitting your sighting, please try again. If this problem persists, please send an email to support@ala.org.au.<br>${result.error}"
                if (sighting.occurrenceID) {
                    chain action: "edit", id: "${sighting.occurrenceID?:''}", model: [sighting: sighting]
                } else {
                    chain action: "index", id: "${sighting.taxonConceptID?:''}", model: [sighting: sighting]
                }
            } else {
                flash.message = "You sighting was successfully submitted."
                redirect(uri:'/sightings/user')
            }
        }
    }

    private JSONObject getTaxonForGuid(String guid) {
        JSONObject taxon

        if (guid) {
            taxon = httpWebService.getJson("${grailsApplication.config.bie.baseUrl}/ws/species/shortProfile/${guid}.json")
            if (taxon.has('scientificName')) {
                taxon.guid = guid // not provided by /ws/species/shortProfile
            }
        }

        taxon
    }

    private String getGuidForName(String scientificName) {
        JSONObject taxon
        def guid

        if (scientificName) {
            taxon = httpWebService.getJson("${grailsApplication.config.bie.baseUrl}/ws/guid/${scientificName.encodeAsURL()}")

            if (taxon.has('acceptedIdentifier') || taxon.has('identifier')) {
                guid = taxon.acceptedIdentifier?:taxon.identifier
            }
        }

        guid
    }
}
