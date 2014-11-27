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
<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="main"/>
    <title>Submit a sighting</title>
    <r:require modules="fileuploads, exif"/>
    <style type="text/css">

    .fileinput-button {
        position: relative;
        overflow: hidden;
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

    .input-auto {
        width: auto !important;
        height: 24px;
        font-size: 12px;
        line-height: 20px;
        margin-bottom: 2px;
    }

    label {
        display: inline-block;
    }

    select {
        height: 26px;
        width: auto;
        font-size: 13px;
        line-height: 18px;
        margin-bottom: 4px;
    }

    /*#species input[type='text'] {*/
    /*height: 20px;*/
    /* width: auto; */
    /*font-size: 11px;*/
    /*line-height: 18px;*/
    /*margin-bottom: 4px;*/
    /*}*/

    span.sciName {
        display: inline-block;
        font-size: 15px;
        font-weight: bold;
        font-style: italic;
    }

    span.commonName {
        display: inline-block;
        font-size: 13px;
    }

    table.countTable td {
        padding: 10px 5px 10px 0;
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
        $(function () {
            // console.log("jquery check", $('#species').text());
            // upload code taken from http://blueimp.github.io/jQuery-File-Upload/basic-plus.html
            var url = '${createLink(uri:"/ajaxUpload/upload")}';
            var imageCount = 0;

            $('#fileupload').fileupload({
                url: url,
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
                console.log("node index", node.data('imageIndex'));
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
                        lat = ((Number(lat[0]) + Number(lat[1])/60 + Number(lat[2])/3600) * (latRef == "N" ? 1 : -1)).toFixed(8);
                        lng = ((Number(lng[0]) + Number(lng[1])/60 + Number(lng[2])/3600) * (lngRef == "W" ? -1 : 1)).toFixed(8);
                        hasMetaData = true;
                        node.find('.imgCoords').empty().append(lat + ", " + lng).data('lat',lat).data('lng',lng);
                    }

                    var dateTime = (data.exif.getText('DateTimeOriginal') != 'undefined') ? data.exif.getText('DateTimeOriginal') : null;// || data.exif.getText('DateTime');
                    var gpsDate = (data.exif.getText('GPSDateStamp') != 'undefined') ? data.exif.getText('GPSDateStamp') : null;
                    var gpsTime = (data.exif.getText('GPSTimeStamp') != 'undefined') ? data.exif.getText('GPSTimeStamp') : null;

                    if (gpsDate && gpsTime) {
                        // add date & time from GPS (in Zulu time)
                        hasMetaData = true;
                        var timeArr = gpsTime.split(','), timeArr2 = [];
                        $.each(timeArr, function(i, e) {
                            // correct for missing leading zeros on values: 2 -> 02
                            timeArr2.push(('0' + parseInt(e)).slice(-2));
                        });
                        //var timeStr = ('0' + timeArr[0]).slice(-2)
                        var date = gpsDate.replace(/:/g,'-') + 'T' + timeArr2.join(':') + 'Z'; // ISO date format
                        node.find('.imgDate').html(date);
                        node.find('.imgDate').data('date', date);
                        // TODO: add the next line to the function when user clicks 'Use image metadata'
                        //node.find('#timeZoneOfset').val('0'); // UTC time so no offset
                    }
                    else if (dateTime) {
                        // add date & time
                        hasMetaData = true;
                        var isoDateStr = parseExifDateTime(dateTime) || dateTime;
                        node.find('.imgDate').html(isoDateStr);
                        node.find('.imgDate').data('date', isoDateStr);
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
                var result = data.result;
                if (result.success) {
                    var link = $('<a>')
                        .attr('target', '_blank')
                        .prop('href', result.url);
                    node.find('.preview').wrap(link);
                    // populate hidden input fields
                    node.find('.identifier').val(result.url).attr('name', 'associatedMedia['+ index + '].identifier');
                    node.find('.title').val(result.filename).attr('name', 'associatedMedia['+ index + '].title');
                    node.find('.format').val(result.mimeType).attr('name', 'associatedMedia['+ index + '].format');
                    node.find('.creator').val("${user?.userDisplayName?:'ALA User'}").attr('name', 'associatedMedia['+ index + '].creator');
                    node.find('.license').val($('#imageLicense').val()).attr('name', 'associatedMedia['+ index + '].license');
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
            var offset = new Date().getTimezoneOffset() * -1;
            var hours = offset / 60;
            var minutes = offset % 60;
            var prefix = (hours >= 0) ? '+' : '-';
            $('#timeZoneOffset').val(prefix + ('0' + hours).slice(-2) + ':' + ('0' + minutes).slice(-2));

            $('#files').on('click', 'button.imageData', function() {
                //console.log('imageData', e, this);
                insertImageMetadata($(this).parents('.imageRow'));
                return false;
            });

            $('#files').on('click', 'button.imageRemove', function() {
                $(this).parents('.imageRow').remove();
            });

            $('#imageLicense').change(function() {
                $('input.license').val($(this).val());
            });

        });

        function insertImageMetadata(imageRow) {
            // imageRow is a jQuery object
            var dateTime = imageRow.find('.imgDate').data('date');
            if (dateTime) {
                $('#date').val(dateTime.substring(0,10));
                $('#time').val(dateTime.substring(11,19));
                $('#timeZoneOffset').val(dateTime.substring(19));
            }
            var lat = imageRow.find('.imgCoords').data('lat');
            var lng = imageRow.find('.imgCoords').data('lng');
            if (lat && lng) {
                $('#decimalLatitude').val(lat);
                $('#decimalLongitude').val(lng);
                $('#georeferenceProtocol').val('camera/phone');
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
        function parseExifDateTime(dataTimeStr) {
            //first split on space to get date and time parts
            console.log('dataTimeStr', dataTimeStr);
            //var dateTimeObj;
            var bigParts = dataTimeStr.split(' ');

            if (bigParts.length == 2) {
                var date = bigParts[0].split(':');
                //var time = bigParts[1].split(':');
                var offset = $('#timeZoneOffset').val() || '+10:00';
                //offset = (offset >= 0) ? '+' + offset : offset;
                var isoDateStr = date.join('-') + 'T' + bigParts[1] + offset;
                %{--try {--}%
                    %{--dateTimeObj = new Date(isoDateStr); // TODO add timezone support (ask user)--}%
                %{--} catch(ex) {--}%
                    %{--console.error("Error parsing EXIF date time: " + isoDateStr, ex);--}%
                %{--}--}%
                %{--console.log('isoDateStr', isoDateStr, dateTimeObj);--}%
            }

            return isoDateStr;
        }

    </r:script>
</head>
<body class="nav-species">
<h2>Submit a Sighting</h2>
<form action="${g.createLink(controller:'submitSighting', action:'upload')}" method="POST">
<div class="bs-docs-example" id="species" data-content="Species">
    <g:set var="speciesSearchForm">
        <div class="input-append">
            <input class="input-xlarge" id="speciesLookup" type="text">
            <button class="btn" type="button">Undo</button>
        </div>
    </g:set>
    <div id="noGuid" class="${taxon?.guid ? 'hide' : ''}">
        <div class="noTaxa">Type a scientific or common name into the box below and choose from the auto-complete list.</div>
        ${raw(speciesSearchForm)}
    </div>
    <div class="row-fluid ${taxon?.guid ? '':'hide'}">
        <div class="span8">
            <g:if test="${taxon}">
                <span class="sciName">
                    <a href="${grailsApplication.config.bie.baseUrl}/species/${taxon.guid}" title="view species page" target="BIE">${taxon.scientificName}</a>
                </span>
                <span class="commonName">${taxon.commonName}</span>
                <g:if test="${taxon.thumbnail}">
                    <img src="${taxon.thumbnail}" class="speciesThumbnail" alt="thumbnail image of ${taxon.commonName?:taxon.scientificName}"/>
                </g:if>
            </g:if>
            <g:else>
                <span class="noTaxa">Type a scientific or common name into the box below and choose from the auto-complete list.</span>
                ${raw(speciesSearchForm)}
            </g:else>
            <table class="countTable">
                <tr>
                    <td><label for="individualCount">Number seen:</label></td>
                    %{--<td><input type="text" name="individualCount" class="input-small input-auto smartspinner" value="1" size="2" data-validation-engine="validate[custom[integer], min[1]]" id="individualCount"></td>--}%
                    <td><g:select from="${0..99}" name="individualCount" class="input-small input-auto smartspinner" value="${1}" data-validation-engine="validate[custom[integer], min[1]]" id="individualCount"/></td>
                    <td><label for="identificationVerificationStatus">Confidence in identification:</label></td>
                    <td><select name="identificationVerificationStatus" id="identificationVerificationStatus" class="">
                        <option value="Confident">Confident</option>
                        <option value="Uncertain">Uncertain</option>
                    </select></td>
                </tr>
            </table>
        </div>
        <div class="${taxon?.guid ? '':'hide'} span4" id="searchAgain">
            Not the right species? To change identification, type a scientific
            or common name into the box below and choose from the auto-complete list.
            ${raw(speciesSearchForm)}
        </div>
    </div>
    <input type="hidden" name="guid" id="guid" value="${taxon?.guid}"/>
    <input type="hidden" name="scientificName" id="scientificName" value="${taxon?.scientificName}"/>
</div>

<div class="bs-docs-example" id="media" data-content="Media">
    <!-- The fileinput-button span is used to style the file input field as button -->
    <span class="btn btn-success fileinput-button tooltips" title="Select one or more photos to upload (you can also simply drag and drop files onto the page).">
        <i class="icon icon-white icon-plus"></i>
        <span>Add files...</span>
        <!-- The file input field used as target for the file upload widget -->
        <input id="fileupload" type="file" name="files[]" multiple>
    </span>
    <span style="display: inline-block; margin-left: 10px;">Optional. If you have any photos, then add them here and we'll attempt
    to pull out date and location information from the photo metadata.</span>
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
        <select name="imageLicense " id="imageLicense">
            <option value="Creative Commons Attribution">Creative Commons Attribution</option>
            <option value="Creative Commons Attribution-Noncommercial">Creative Commons Attribution-Noncommercial</option>
            <option value="Creative Commons Attribution-Share Alike">Creative Commons Attribution-Share Alike</option>
            <option value="Creative Commons Attribution-Noncommercial-Share Alike">Creative Commons Attribution-Noncommercial-Share Alike</option>
        </select>
    </div>
</div>

<div class="bs-docs-example" id="dateTime" data-content="Date &amp; Time">
    <label for="date">Date (dd-mm-yyyy):</label>
    <input type="text" name="date" id="date" class="input-auto" value="${sighting?.date}"/>
    <label for="date">Time (24 hour time in hh:mm):</label>
    <input type="text" name="time" id="time" class="input-auto" value="${sighting?.time}"/>
    %{--<label for="timeZoneOffset">Timezone offset</label>--}%
    %{--<input type="text" name="timeZoneOffset" id="timeZoneOffset" value="${sighting?.timeZoneOffset}"/>--}%
    <input type="hidden" name="timeZoneOffset" id="timeZoneOffset" value="${sighting?.timeZoneOffset}"/>
</div>

<div class="bs-docs-example" id="location" data-content="Location">
    <div class="">
        <label for="decimalLatitude">Latitiude (decimal):</label>
        <input type="text" name="decimalLatitude" id="decimalLatitude" class="input-auto" value="${sighting?.decimalLatitude}"/>
        <label for="decimalLongitude">Longitude (decimal):</label>
        <input type="text" name="decimalLongitude" id="decimalLongitude" class="input-auto" value="${sighting?.decimalLongitude}"/>
        <label for="coordinateUncertaintyInMeters">Accuracy (metres):</label>
        <input type="text" name="coordinateUncertaintyInMeters" id="coordinateUncertaintyInMeters" class="input-auto" value="${sighting?.coordinateUncertaintyInMeters}"/>
        <br>
        <label for="georeferenceProtocol">Source of coordinates:</label>
        <g:select from="${coordinateSources}" id="georeferenceProtocol" name="georeferenceProtocol" value="${sighting?.georeferenceProtocol}"/>
        <label for="locationRemark">Location description:</label>
        <textarea id="locationRemark" name="locationRemark" class="" rows="2" value="${sighting?.decimalLatitude}">${sighting?.locationRemark}</textarea>
    </div>
</div>

<div class="bs-docs-example" id="details" data-content="Notes">
    <section class="sightings-block ui-corner-all">
        %{--<label for="occurrenceRemarks">Notes</label>--}%
        <textarea name="occurrenceRemarks" rows="4" cols="90" id="occurrenceRemarks">${sighting?.occurrenceRemarks}</textarea>
    </section>
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
            <input type="hidden" class="title" value=""/>
            <input type="hidden" class="format" value=""/>
            <input type="hidden" class="identifier" value=""/>
            <input type="hidden" class="license" value=""/>
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
</div>
</form>
</body>
</html>