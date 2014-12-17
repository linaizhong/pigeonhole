%{--
  - Copyright (C) 2014 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
  --}%

<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 6/11/2014
  Time: 4:35 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ page import="grails.converters.JSON" contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="main"/>
    <title>Submit a sighting</title>
    <r:require modules="fileuploads, exif, moment, alaAutocomplete, sightingMap, datepicker, qtip"/>
    <style type="text/css">

    .fileinput-button {
        position: relative;
        overflow: hidden;
        vertical-align: top;
        margin: 4px 5px 5px 0;
    }
    .fileinput-button input {
        position: absolute;
        top: 0;
        right: 0;
        margin: 0;
        opacity: 0;
        -ms-filter: 'alpha(opacity=0)';
        font-size: 200px;
        direction: ltr;
        cursor: pointer;
    }

    .form-horizontal {
        line-height: 3;
    }

    .input-auto {
        width: auto !important;
        height: 24px;
        font-size: 12px;
        line-height: 20px;
        margin-bottom: 2px;
    }

    .validationErrors:not(.tt-hint)  {
        border: 1px solid red !important;
        /*color: red;*/
    }

    label {
        display: inline-block;
    }

    select.slim {
        height: 26px;
        width: auto;
        font-size: 13px;
        line-height: 18px;
        margin-bottom: 4px;
    }
    select.slim2 {
        height: 26px;
        width: auto;
        font-size: 13px;
        line-height: 18px;
    }

    select.narrow {
        width: auto;
        margin-bottom: 0px;
    }

    input#speciesLookup {
        /*margin-top: 5px;*/
    }

    #species .label {
        font-size: 12px;
        font-weight: normal;
        padding: 9px 10px 7px;
        margin-right: 5px;
    }

    a.remove {
        display: inline-block;
        vertical-align: top;
        margin-left: 5px;
        margin-top: -2px;
    }

    #tagsBlock {
        margin: 10px 0;
    }
    
    .helphint {
        display: inline-block;
        margin-bottom: 5px;
        color: grey;
    }

    /*#species input[type='text'] {*/
    /*height: 20px;*/
    /* width: auto; */
    /*font-size: 11px;*/
    /*line-height: 18px;*/
    /*margin-bottom: 4px;*/
    /*}*/

    #species .row-fluid .span6 {
        display: table-cell;
        /*vertical-align: bottom;*/
        float: none;
    }

    #mapWidget {
        /*margin-top: -20px;*/
    }

    #mapWidget > .input-append, #mapWidget > .btn, #mapWidget > .label {
        display: inline-block;
        margin-bottom: 0;
        margin-top: 5px;
    }
    #mapWidget #map {
        margin: 10px 0;
    }
    #taxonDetails {
        margin-bottom: 5px;
        display: inline-block;
    }
    #taxonDetails table {
        display: inline-block;
    }
    #taxonDetails table td {
        padding: 5px 9px 0px 4px;
    }

    #identificationChoice {
        margin-bottom: 15px;
    }

    #speciesMisc {
        margin-top: 10px;
    }

    .sciName {
        display: block;
        font-size: 14px;
        font-weight: bold;
        font-style: italic;
        margin-bottom: 10px;
    }

    .sciName a {
        /*color: white;*/
    }

    .commonName {
        display: block;
        font-size: 13px;
    }

    table.formInputTable {
        margin: 5px 0 5px 0;
    }

    table.formInputTable td {
        padding: 1px 8px 1px 0;
    }

    #occurrenceRemarks {
        width: 80%;
    }

    /* Fixes for IE < 8 */
    @media screen\9 {
        .fileinput-button input {
            filter: alpha(opacity=0);
            font-size: 100%;
            height: 100%;
        }
    }

    </style>
    <r:script>
        // global var to pass in GSP/Grails values into external JS files
        GSP_VARS = {
            biocacheBaseUrl: "${(grailsApplication.config.biocache.baseUrl)}",
            bieBaseUrl: "${(grailsApplication.config.bie.baseUrl)}",
            uploadUrl: "${createLink(uri:"/ajaxUpload/upload")}",
            guid: "${taxon?.guid}",
            leafletImagesDir: "${g.createLink(uri:'/js/leaflet-0.7.3/images')}"
        };


        $(function () {
            // console.log("jquery check", $('#species').text());
            // upload code taken from http://blueimp.github.io/jQuery-File-Upload/basic-plus.html
            var imageCount = 0;

            $('#fileupload').fileupload({
                url: GSP_VARS.uploadUrl,
                dataType: 'json',
                autoUpload: true,
                acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i,
                maxFileSize: 5000000, // 5 MB
                // Enable image resizing, except for Android and Opera,
                // which actually support image resizing, but fail to
                // send Blob objects via XHR requests:
                disableImageResize: /Android(?!.*Chrome)|Opera/
                    .test(window.navigator.userAgent),
                previewMaxWidth: 100,
                previewMaxHeight: 100,
                previewCrop: true
            }).on('fileuploadadd', function (e, data) {
                // load event triggered (start)
                //console.log('fileuploadadd', data);
                // Clone the template and reference it via data.context
                data.context = $('#uploadActionsTmpl').clone(true).removeAttr('id').removeClass('hide').appendTo('#files');
                $.each(data.files, function (index, file) {
                    console.log('file', file);
                    var node = $(data.context[index]);
                    node.find('.filename').append(file.name + '  (' + humanFileSize(file.size) + ')');
                    //node.attr('id', 'image_'+ imageCount++);
                    node.data('index', imageCount++);
                    $('#imageLicenseDiv').removeClass('hide'); // show the license options
                    //console.log('node data', node);
                });
            }).on('fileuploadprocessalways', function (e, data) {
                // next event after 'add' setup progress bar, etc
                console.log('fileuploadprocessalways', data);
                var index = data.index,
                    file = data.files[index],
                    hasMetaData = false,
                    node = $(data.context[index]); // grab the current image node (created via a template)
                console.log("node index", node.data('imageIndex'), file);
                if (file.preview) {
                    // add preview image
                    node.find('.preview').append(file.preview);
                }

                if (data.exif) {
                    // add EXIF data (date, location, etc)
                    console.log('exif tags', data.exif, data.exif.getAll());
                    // GPS coordinates are in deg/min/sec -> convert to decimal
                    var lat = data.exif.getText('GPSLatitude'); // getText returns "undefined" as a String if not set!
                    var lng = data.exif.getText('GPSLongitude'); // getText returns "undefined" as a String if not set!

                    if (lat != "undefined" && lng != "undefined") {
                        // add GPS data
                        console.log('lat lng', lat, lng);
                        lat = lat.split(',');
                        lng = lng.split(',');
                        var latRef = data.exif.getText('GPSLatitudeRef') || "N";
                        var lngRef = data.exif.getText('GPSLongitudeRef') || "W";
                        lat = ((Number(lat[0]) + Number(lat[1])/60 + Number(lat[2])/3600) * (latRef == "N" ? 1 : -1)).toFixed(10);
                        lng = ((Number(lng[0]) + Number(lng[1])/60 + Number(lng[2])/3600) * (lngRef == "W" ? -1 : 1)).toFixed(10);
                        hasMetaData = true;
                        node.find('.imgCoords').empty().append(lat + ", " + lng).data('lat',lat).data('lng',lng);
                    }

                    var dateTime = (data.exif.getText('DateTimeOriginal') != 'undefined') ? data.exif.getText('DateTimeOriginal') : null;// || data.exif.getText('DateTime');
                    var gpsDate = (data.exif.getText('GPSDateStamp') != 'undefined') ? data.exif.getText('GPSDateStamp') : null;
                    var gpsTime = (data.exif.getText('GPSTimeStamp') != 'undefined') ? data.exif.getText('GPSTimeStamp') : null;

                    if (gpsTime && dateTime) {
                        // determine local time offset from UTC
                        // by working out difference between DateTimeOriginal and GPSTimeStamp to get timezone (offset)
                        // gpsDate is not always set - if absent assume same date as 'DateTimeOriginal'
                        var date = gpsDate || dateTime.substring(0,10); //dateTime.substring(0,10)
                        date = date.replace(/:/g,'-') + ' ' + parseGpsTime(gpsTime); // comvert YYYY:MM:DD to YYYY-MM-DD
                        var gpsMoment = moment(date);
                        var datetimeTemp = parseExifDateTime(dateTime, false);
                        var localMoment = moment(datetimeTemp);
                        var gpsDiff = localMoment.diff(gpsMoment, 'minutes');
                        var prefix = (gpsDiff >= 0) ? '+' : '';
                        var gpsOffset = prefix + moment.duration(gpsDiff, 'minutes').format("hh:mm");
                        $('#timeZoneOffset').val(gpsOffset);
                        //console.log('gpsDate 1', date, '|', gpsMoment.format());
                        //console.log('gpsDate 2', datetimeTemp, '|', localMoment.format());
                        //console.log('diff', gpsOffset, gpsOffset);
                        hasMetaData = true;
                    }
                    if (dateTime) {
                        // add date & time
                        hasMetaData = true;
                        var isoDateStr = parseExifDateTime(dateTime, true) || dateTime;
                        node.find('.imgDate').html(isoDateStr);
                        if (! node.find('.imgDate').data('datetime')) {
                            node.find('.imgDate').data('datetime', isoDateStr);
                        }
                    } else if (gpsDate) {
                        hasMetaData = true;
                        var isoDateStr = gpsDate.replace(/:/g,'-');
                        node.find('.imgDate').html(isoDateStr);
                        if (! node.find('.imgDate').data('datetime')) {
                            node.find('.imgDate').data('datetime', isoDateStr);
                        }
                    }

                    if (hasMetaData) {
                        // activate the button
                        node.find('.imageData').removeAttr('disabled').attr('title','Use image date/time & GPS coordinates for this sighting');
                    }
                }
                if (file.error) {
                    node.find('.error')
                        //.append('<br>')
                        .append($('<span class="text-danger"/>').text(file.error));
                }
            }).on('fileuploadprogressall', function (e, data) {
                // progress metre - gets triggered mulitple times
                console.log('fileuploadprogressall', data);
                var progress = parseInt(data.loaded / data.total * 100, 10);
                $('#progress .progress-bar').css(
                    'width',
                    progress + '%'
                );
            }).on('fileuploaddone', function (e, data) {
                // file has successfully uploaded
                console.log('fileuploaddone', data);
                var node = $(data.context[0]);
                //var index = node.attr('id').replace("image_", "");
                var index = node.data('index');
                var result = data.result; // ajax results
                if (result.success) {
                    var link = $('<a>')
                        .attr('target', '_blank')
                        .prop('href', result.url);
                    node.find('.preview').wrap(link);
                    // populate hidden input fields
                    //node.find('.media').val(result.url).attr('name', 'associatedMedia['+ index + ']');
                    node.find('.identifier').val(result.url).attr('name', 'multimedia['+ index + '].identifier');
                    node.find('.title').val(result.filename).attr('name', 'multimedia['+ index + '].title');
                    node.find('.format').val(result.mimeType).attr('name', 'multimedia['+ index + '].format');
                    node.find('.creator').val("${user?.userDisplayName?:'ALA User'}").attr('name', 'multimedia['+ index + '].creator');
                    node.find('.license').val($('#imageLicense').val()).attr('name', 'multimedia['+ index + '].license');
                    if (result.exif && result.exif.date) {
                        node.find('.created').val(result.exif.date).attr('name', 'multimedia['+ index + '].created');
                    }
                    insertImageMetadata(node);
                } else if (data.error) {
                // in case an error still returns a 200 OK... (our service shouldn't)
                    var error = $('<div class="alert alert-error"/>').text(data.error);
                    node.append(error);
                }
            }).on('fileuploadfail', function (e, data) {
                console.log('fileuploadfail', data);
                $.each(data.files, function (index, file) {
                    var error = $('<div class="alert alert-error"/>').text('File upload failed.');
                    $(data.context.children()[index])
                        //.append('<br>')
                        .append(error);
                });
            }).prop('disabled', !$.support.fileInput)
            .parent().addClass($.support.fileInput ? undefined : 'disabled');

            // pass in local time offset from UTC
            //var offset = ( new Date().getTimezoneOffset() / 60 ) * -1; // converted to hours (e.g. +11)
            console.log('initialoffset', $('#timeZoneOffset').val());
            var offset = new Date().getTimezoneOffset() * -1;
            var hours = offset / 60;
            var minutes = offset % 60;
            var prefix = (hours >= 0) ? '+' : '';
            $('#timeZoneOffset').val(prefix + ('0' + hours).slice(-2) + ':' + ('0' + minutes).slice(-2));

            // use image data button
            $('#files').on('click', 'button.imageData', function() {
                //console.log('imageData', e, this);
                insertImageMetadata($(this).parents('.imageRow'));
                return false;
            });

            // remove image button
            $('#files').on('click', 'button.imageRemove', function() {
                $(this).parents('.imageRow').remove();
            });

            // image license drop-down
            $('#imageLicense').change(function() {
                $('input.license').val($(this).val());
            });

            // Clear the #eventDateNoTime field (extracted from photo EXIF data) if user changes either the date or time field
            $('#eventDateNoTime, #eventTime').keyup(function() {
                $('#eventDateTime').val('');
            });

            // close button on bootstrap alert boxes
            $("[data-hide]").on("click", function(){
                $(this).closest("." + $(this).attr("data-hide")).hide();
                clearTaxonDetails();
            });

            // species group drop-down
            var speciesGroupsObj = ${(speciesGroupsMap).encodeAsJson()?:'{}'};
            $('#speciesGroups').change(function(e) {
                var group = $(this).val();
                var noSelectOpt = '-- Choose a sub group --'; //$('#speciesSubgroups option:first-child').text();
                console.log('noSelectOpt', noSelectOpt, group);
                $('#speciesSubgroups').empty().append($("<option/>").attr("value","").text(noSelectOpt));

                if (group) {
                    $.each(speciesGroupsObj[group], function(i, el) {
                        $('#speciesSubgroups')
                            .append($("<option/>")
                            .attr("value",el.common)
                            .text(el.common));
                    });
                    addTagLabel(group);
                    $('#browseSpecesImages').removeClass('disabled').removeAttr('disabled');
                } else {
                    $('#browseSpecesImages').addClass('disabled').attr('disabled','');
                }
            });

            // species subgroup drop-down
            $('#speciesSubgroups').change(function(e) {
                addTagLabel($(this).val());
            });

            // remove species/secientificName box
            $('#species').on('click', 'a.remove', function(e) {
                e.preventDefault();
                $(this).parent().hide();
            });

            // autocomplete on species lookup
            $('#speciesLookup').alaAutocomplete({maxHits: 15}); // will trigger a change event on #guid when item is selected

            // detect change on #guid input (autocomplete selection) and load spceies details
            $('#guid').change(function(e) {
                $('#speciesLookup').alaAutocomplete.reset();
                var guid = $(this).val();

                if (guid) {
                    $.getJSON("${grailsApplication.config.bie.baseUrl}/ws/species/shortProfile/" + guid + ".json?callback=?")
                    .done(function(data) {
                        if (data.scientificName) {
                            $('#taxonDetails').removeClass('hide').show();

                            $('.sciName a').attr('href', "${grailsApplication.config.bie.baseUrl}/species/" + guid).html(data.scientificName);
                            $('.speciesThumbnail').attr('src', '${grailsApplication.config.bie.baseUrl}/ws/species/image/thumbnail/' + guid);
                            if (data.commonName) {
                                $('.commonName').text(data.commonName);
                            } else {
                                //$('.commonName').hide();
                            }
                            $('#noTaxa').hide();
                            $('#matchedTaxa').show();
                        }
                    })
                    .fail(function( jqXHR, textStatus, errorThrown ) {
                        alert("Error: " + textStatus + " - " + errorThrown);
                    })
                    .always(function() {
                        // clean-up & spinner deactivations, etc
                    });
                }

            });

            // update map in edit mode
            if ("${sighting?.decimalLongitude}") {
                // trigger map to refresh
                $('#decimalLongitude').change();
            }

            // show tags in edit mode
            var tags = ${(sighting?.tags).encodeAsJson()?:'[]'};
            $.each(tags, function(i, t) {
                addTagLabel(t);
            });

            // show images in edit mode
            var media = ${(sighting?.multimedia).encodeAsJson()?:'[]'};
            $.each(media, function(i, m) {
                console.log("image", m);
                addServerImage(m, i);
            });

            // init date picker
            $('#eventDateNoTime').datepicker({format: 'dd-mm-yyyy'});

            // clear validation errors red border on input blur
            $('.validationErrors').on('blur', function(e) {
                $(this).removeClass('validationErrors');
            });

            // click event on confidence button group
            $('#confident, #uncertain').click(function(e) {
                e.preventDefault();
                var $this = this;
                var highlightClass = 'btn-primary';
                $('#confident, #uncertain').removeClass(highlightClass);
                $('#showConfident, #showUncertain').addClass('hide');
                $($this).addClass(highlightClass);
                $('#speciesMisc').removeClass('hide')
                if ($($this).attr('id') == 'confident') {
                    $('#showConfident').removeClass('hide');
                    $('#identificationVerificationStatus').val('Confident');
                    $('#requireIdentification').prop('checked', false);
                } else {
                    $('#showUncertain').removeClass('hide');
                    $('#identificationVerificationStatus').val('Uncertain');
                    $('#requireIdentification').prop('checked', true);
                }
            });

            // load species info if id is in the URL
            if (GSP_VARS.guid) {
                $('#guid').val(GSP_VARS.guid).change();
                $('#confident').trigger( "click" );
            }

            // init qtip (tooltip)
            $('.tooltips').qtip({
                style: {
                    classes: 'ui-tooltip-rounded ui-tooltip-shadow'
                },
                position: {
                    target: 'mouse',
                    adjust: { x: 6, y: 14 }
                }
            });

        });

        function insertImageMetadata(imageRow) {
            // imageRow is a jQuery object
            var dateTime = imageRow.find('.imgDate').data('datetime');
            if (dateTime) {
                $('#eventDateTime').val(dateTime);
                $('#eventDateNoTime').val(isoToAusDate(dateTime.substring(0,10)));
                $('#eventTime').val(dateTime.substring(11,19));
                $('#timeZoneOffset').val(dateTime.substring(19));
            }
            var lat = imageRow.find('.imgCoords').data('lat');
            var lng = imageRow.find('.imgCoords').data('lng');
            if (lat && lng) {
                $('#decimalLatitude').val(lat).change();
                $('#decimalLongitude').val(lng).change();
                $('#georeferenceProtocol').val('camera/phone');
            }
        }

        function writeImageBlock(ajaxResult) {

        }

        function isoToAusDate(isoDate) {
            var dateParts = isoDate.substring(0,10).split('-');
            var ausDate = isoDate.substring(0,10); // fallback

            if (dateParts.length == 3) {
                ausDate = dateParts.reverse().join('-');
            }

            return ausDate;
        }

        function clearTaxonDetails() {
            $('#taxonDetails .commonName').html('');
            $('#taxonDetails img').attr('src','');
            $('#taxonDetails a').attr('href','').html('');
            $('#guid, #scientificName').val('');
        }

        /**
        * Adds a visual tag (label/badge) to the page when either group/subgroup select changes
        *
        * @param group
        */
        function addTagLabel(group) {
            if (group) {
                var close = '<a href="#" class="remove" title="remove this item"><i class="remove icon-remove icon-white">&nbsp;</i></a>';
                var input = '<input type="hidden" value="' + group + '" name="tags"/>';
                var label = $('<span class="label label-infoX"/>').append(input + group + close).after('&nbsp;');
                $('#tagsBlock').append(label);
            }
        }

        /**
        * Convert bytes to human readable form.
        * Taken from http://stackoverflow.com/a/14919494/249327
        *
        * @param bytes
        * @param si
        * @returns {string}
        */
        function humanFileSize(bytes, si) {
            var thresh = si ? 1000 : 1024;
            if(bytes < thresh) return bytes + ' B';
            //var units = si ? ['kB','MB','GB','TB','PB','EB','ZB','YB'] : ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];
            var units =  ['kB','MB','GB','TB','PB','EB','ZB','YB'];
            var u = -1;
            do {
                bytes /= thresh;
                ++u;
            } while(bytes >= thresh);
            return bytes.toFixed(1)+' '+units[u];
        };

        /**
        * Parse the weird date time format in EXIF data (TIFF format)
        *
        * @param dataTimeStr
        * @returns dateTimeObj (JS Date)
        */
        function parseExifDateTime(dataTimeStr, includeOffset) {
            //first split on space to get date and time parts
            console.log('dataTimeStr', dataTimeStr);
            //var dateTimeObj;
            var bigParts = dataTimeStr.split(' ');

            if (bigParts.length == 2) {
                var date = bigParts[0].split(':');
                //var time = bigParts[1].split(':');
                var offset = $('#timeZoneOffset').val() || '+10:00';
                //offset = (offset >= 0) ? '+' + offset : offset;
                var isoDateStr = date.join('-') + 'T' + bigParts[1];
                if (includeOffset) {
                    isoDateStr += offset;
                } else {
                    isoDateStr = isoDateStr.replace('T', ' ');
                }
                //alert('includeOffset = ' + includeOffset + ' - ' + isoDateStr);
            }

            return isoDateStr;
        }

        function parseGpsTime(time) {
            // e.g. 15,5,8.01
            var bits = [];
            $.each(time.split(','), function(i, it) {
                bits.push(('0' + parseInt(it)).slice(-2)); // zero pad
            });
            return bits.join(':');
        }

        function addServerImage(image, index) {
            var node = $('#uploadActionsTmpl').clone(true).removeAttr('id').removeClass('hide'); //.appendTo('#files');
            node.find('.filename').append(image.title); // add filesize -  humanFileSize(file.size)

            var link = $('<a>')
                .attr('target', '_blank')
                .prop('href', image.identifier);
            node.find('.preview').wrap(link);
            node.find('.preview').append($('<img/>').attr('src',image.identifier)).attr('style','height:100px;width:100px');
            // populate hidden input fields
            //node.find('.media').val(result.url).attr('name', 'associatedMedia['+ index + ']');
            node.find('.identifier').val(image.identifier).attr('name', 'multimedia['+ index + '].identifier');
            node.find('.title').val(image.title).attr('name', 'multimedia['+ index + '].title');
            node.find('.format').val(image.mimeType).attr('name', 'multimedia['+ index + '].format');
            node.find('.creator').val(image.creator).attr('name', 'multimedia['+ index + '].creator');
            node.find('.license').val(image.creator).attr('name', 'multimedia['+ index + '].license');

            if (false) {
            //if (result.exif && result.exif.date) {
                node.find('.created').val(result.exif.date).attr('name', 'multimedia['+ index + '].created');
            }

            node.appendTo('#files');
        }

    </r:script>
</head>
<body class="nav-species">
<g:render template="/topMenu" />
<h2>Submit a Sighting</h2>
<g:hasErrors bean="${sighting}">
    <div class="container-fluid">
        <div class="alert alert-error">
            ${flash.message}
            <g:eachError var="err" bean="${sighting}">
                <li><g:message code="sighting.field.${err.field}"/> - <g:fieldError bean="${sighting}"  field="${err.field}"/></li>
            </g:eachError>
        </div>
    </div>
</g:hasErrors>
<form id="sightingForm" action="${g.createLink(controller:'submitSighting', action:'upload')}" method="POST">

<!-- Species -->
<div class="boxed-heading" id="species" data-content="Species">
    <div class="row-fluid">
        <div class="span6">
            <div id="identificationChoice">
                <div>How sure are you with the species identification?</div>
                <div class="btn-group">
                    <button class="btn tooltips" id="confident" title="I know the common name or scientific name"><b>Confident</b></button>
                    <button class="btn tooltips" id="uncertain" title="I'm not sure of the name"><b>Uncertain</b></button>
                </div>
            </div>
            <div id="taxonDetails" class="well well-small" style="display: none;">
                <table>
                    <tr>
                        <td><img src="" class="speciesThumbnail" alt="thumbnail image of species" style="width:75px; height:75px;"/></td>
                        <td>
                            <div class="sciName">
                                <a href="" class="tooltips" title="view species page" target="BIE">species name</a>
                            </div>
                            <div class="commonName">common name</div>
                        </td>
                    </tr>
                </table>
                <input type="hidden" name="guid" id="guid" value="${taxon?.guid}"/>
                <input type="hidden" name="scientificName" id="scientificName" value="${taxon?.scientificName}"/>
                <input type="hidden" name="identificationVerificationStatus" id="identificationVerificationStatus" value="${taxon?.identificationVerificationStatus}"/>
                <a href="#" class="remove" title="remove this item"><i class="remove icon-remove">&nbsp;</i></a>
            </div>
            <div id="tagsBlock"></div>

        </div>
        <div class="span6">
            <div id="showConfident" class="hide">
                <div id="noTaxa" style="display: inherit;">Type a scientific or common name into the box below and choose from the auto-complete list.</div>
                <div id="matchedTaxa" style="display: none;">Not the right species? To change identification, type a scientific
                or common name into the box below and choose from the auto-complete list.</div>
                <input class="input-xlarge typeahead ${hasErrors(bean:sighting,field:'scientificName','validationErrors')}" id="speciesLookup" type="text">
            </div>
            <div id="showUncertain" class="hide">
                <div>Narrow identification down to a species group and sub-group:</div>
                <g:select name="tag" from="${speciesGroupsMap?.keySet()}" id="speciesGroups" class="slim ${hasErrors(bean:sighting,field:'scientificName','validationErrors')}" noSelection="['':'-- Species group --']"/>
                <g:select name="tag" from="${[]}" id="speciesSubgroups" class="slim" noSelection="['':'-- Subgroup (select a group first) --']"/>
            </div>
            <div id="speciesMisc" class="hide">
                <label for="requireIdentification" class="checkbox">
                    <g:checkBox id="requireIdentification" name="requireIdentification" value="${(sighting?.requireIdentification)}"/>
                    Ask the Taxon-Overflow community to assist with or confirm the identification (requires a photo of the sighting)
                </label>
            </div>
        </div>
    </div>
</div>

<!-- Media -->
<div class="boxed-heading" id="media" data-content="Media">
    <!-- The fileinput-button span is used to style the file input field as button -->
    <span class="btn btn-success fileinput-button tooltips" title="Select one or more photos to upload (you can also simply drag and drop files onto the page).">
        <i class="icon icon-white icon-plus"></i>
        <span>Add files...</span>
        <!-- The file input field used as target for the file upload widget -->
        <input id="fileupload" type="file" name="files[]" multiple>
    </span>
    <span style="display: inline-block;">Optional. Add one or more images. Image metadata will be used to automatically set date and location fields (where available)
        <br>Hint: you can drag and drop files onto this window</span>
    <br>
    <br>
    <!-- The global progress bar -->
    %{--<div id="progress" class="progress">--}%
        %{--<div class="progress-bar progress-bar-success"></div>--}%
    %{--</div>--}%
    <!-- The container for the uploaded files -->
    <div id="files" class="files"></div>
    <div id="imageLicenseDiv" class="hide">
        <label for="imageLicense">Licence:</label>
        <g:select from="${grailsApplication.config.sighting.licenses}" name="imageLicense" class="slim" id="imageLicense" value="${sighting?.multimedia?.get(0)?.license}"/>
    </div>
</div>

<!-- Location -->
<div class="boxed-heading" id="location" data-content="Location">
    <div class="row-fluid">
        <div class="span6" id="mapWidget">
            <div class="form-horizontal">
                <button class="btn" id="useMyLocation"><i class="icon-map-marker" style="margin-left:-5px;"></i> Use my location</button>
                &nbsp;<span class="badge badge-infoX"> OR </span>&nbsp;
                <div class="input-append">
                    <input class="input-large" id="geocodeinput" type="text" placeholder="Enter an address, location or lat/lng">
                    <button id="geocodebutton" class="btn">Lookup</button>
                </div>
            </div>
            <div id="map" style="width: 100%; height: 280px"></div>
            <div class="" id="mapTips">Hint: drag the marker to fine-tune your location</div>
        </div>
        <div class="span6" style="margin-bottom: 0px;">
            <table class="formInputTable">
                <tr>
                    <td><label for="decimalLatitude">Latitude (decimal):</label></td>
                    <td><input type="text" name="decimalLatitude" id="decimalLatitude" class="input-auto" value="${sighting?.decimalLatitude}"/></td>
                </tr>
                <tr>
                    <td><label for="decimalLongitude">Longitude (decimal):</label></td>
                    <td><input type="text" name="decimalLongitude" id="decimalLongitude" class="input-auto" value="${sighting?.decimalLongitude}"/></td>
                </tr>
                <tr>
                    <td><label for="coordinateUncertaintyInMeters">Accuracy (metres):</label></td>
                    <td><input type="text" name="coordinateUncertaintyInMeters" id="coordinateUncertaintyInMeters" class="input-auto" value="${sighting?.coordinateUncertaintyInMeters?:50}"/></td>
                </tr>
                <tr>
                    <td><label for="georeferenceProtocol">Source of coordinates:</label></td>
                    <td><g:select from="${coordinateSources}" id="georeferenceProtocol" class="slim" name="georeferenceProtocol" value="${sighting?.georeferenceProtocol}"/></td>
                </tr>
                <tr>
                    <td><label for="locality">Matched locality:</label></td>
                    <td><textarea id="locality" name="locality" class="disabled" rows="3">${sighting?.locality}</textarea></td>
                </tr>
                <tr>
                    <td><label for="locationRemark">Location notes:</label></td>
                    <td><textarea id="locationRemark" name="locationRemark" class="" rows="3" value="${sighting?.decimalLatitude}">${sighting?.locationRemark}</textarea></td>
                </tr>
                <tr>
                    <td><label for="locationRemark">Bookmarked locations:</label></td>
                    <td><div class="form-horizontal"><g:select name="bookmarkedLocations" id="bookmarkedLocations" class="slim2" from="${bookmarkedLocations}" noSelection="['':'-- saved locations --']"/>
                        <button id="bookmarkLocation" class="btn btn-small disabled" disabled="disabled">Add Bookmark</button></div></td>
                </tr>
            </table>
        </div>
    </div>
</div>

<!-- Details -->
<div class="boxed-heading" id="details" data-content="Details">
    <div class="row-fluid">
        <div class="span6">
            <table class="formInputTable">
                <tr >
                    <td><label for="eventDateNoTime">Date:</label></td>
                    <td><input type="text" name="eventDateNoTime" id="eventDateNoTime" class="input-auto ${hasErrors(bean:sighting,field:'eventDateNoTime','validationErrors')}" placeholder="DD-MM-YYYY" value="${sighting?.eventDateNoTime}"/></td>
                    <td><span class="helphint">* required</span></td>
                </tr>
                <tr >
                    <td><label for="eventTime">Time:</label></td>
                    <td><input type="text" name="eventTime" id="eventTime" class="input-auto ${hasErrors(bean:sighting,field:'eventTime','validationErrors')}" placeholder="HH:MM[:SS]" value="${sighting?.eventTime}"/></td>
                    <td><span class="helphint">24 hour format</span></td>
                </tr>
                <tr>
                    <td><label for="individualCount">Individuals:</label></td>
                    <td><g:select from="${1..99}" name="individualCount" class="slim input-auto smartspinner" value="${sighting?.individualCount}" data-validation-engine="validate[custom[integer], min[1]]" id="individualCount"/></td>
                    <td><span class="helphint">How many did you see?</span></td>
                </tr>
            </table>
            <input type="hidden" name="eventDateTime" id="eventDateTime" value=""/>
            <input type="hidden" name="timeZoneOffset" id="timeZoneOffset" value="${sighting?.timeZoneOffset}"/>
        </div>
        <div class="span6">
            <section class="sightings-block ui-corner-all" style="vertical-align: top;">
                <label for="occurrenceRemarks" style="vertical-align: top;margin-top: 8px;margin-right: 5px;">Notes: </label>
                <textarea name="occurrenceRemarks" rows="4" cols="90" id="occurrenceRemarks">${sighting?.occurrenceRemarks}</textarea>
            </section>
        </div>
    </div>
</div>

<div style="text-align: center;">
    <input type="submit" id="formSubmit" class="btn btn-large"  value="Submit Record"/>
</div>

<%-- Template HTML used by JS code via .clone() --%>
<div class="hide imageRow row-fluid" id="uploadActionsTmpl">
    <div class="span2"><span class="preview pull-right"></span></div>
    <div class="span10">
        <div class="metadata media">
            Filename: <span class="filename"></span>
            %{--<input type="hidden" class="media" value=""/>--}%
            %{--TODO: convert to a proper form and allow user to change these and other values via a hide/show option--}%
            <input type="hidden" class="title" value=""/>
            <input type="hidden" class="format" value=""/>
            <input type="hidden" class="identifier" value=""/>
            <input type="hidden" class="license" value=""/>
            <input type="hidden" class="created" value=""/>
            <input type="hidden" class="creator" value=""/>
        </div>
        <div class="metadata">
            Image date: <span class="imgDate">not available</span>
        </div>
        <div class="metadata">
            GPS coordinates: <span class="imgCoords">not available</span>
        </div>
            %{--<button class="btn btn-small imageDate">Use image date</button>--}%
            %{--<button class="btn btn-small imageLocation">Use image location</button>--}%
            <button class="btn btn-small btn-info imageData" title="No metadata found" disabled>Use image metadata</button>
            <button class="btn btn-small btn-danger imageRemove" title="remove this image">Remove image</button>
        </div>
        <div class="error hide"></div>
    </div>
</div><!-- /#uploadActionsTmpl-->

<!-- Modal -->
<div id="speciesBrowserModal" class="modal hide fade" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
        <h3 id="myModalLabel">Browse species images</h3>
    </div>
    <div class="modal-body">
        <div id="speciesImages"></div>
    </div>
    <div class="modal-footer">
        <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
        %{--<button class="btn btn-primary">Save changes</button>--}%
    </div>
</div><!-- /#speciesBrowserModal -->
</form>
</body>
</html>