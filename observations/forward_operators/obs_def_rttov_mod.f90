! DART software - Copyright UCAR. This open source software is provided
! by UCAR, "as is", without charge, subject to all terms of use at
! http://www.image.ucar.edu/DAReS/DART/DART_download
!
! $Id$

!----------------------------------------------------------------------
! This module provides support for computing forward operators for
! radiance observations by calling the rttov radiative transfer model.
!
! the additional metadata in each observation includes:
!
!  OBS            X
! rttov
!    sat az/el
!    sun az/el
!    platform
!    instrument
!    channel
!    <anything else useful>
!----------------------------------------------------------------------

! BEGIN DART PREPROCESS KIND LIST
! AIRS_AMSU_RADIANCE,    QTY_RADIANCE
! END DART PREPROCESS KIND LIST


! BEGIN DART PREPROCESS USE OF SPECIAL OBS_DEF MODULE
!   use obs_def_rttov_mod, only : read_rttov_metadata, &
!                                write_rttov_metadata, &
!                          interactive_rttov_metadata, &
!                                get_expected_radiance
! END DART PREPROCESS USE OF SPECIAL OBS_DEF MODULE


! BEGIN DART PREPROCESS GET_EXPECTED_OBS_FROM_DEF
!      case(AIRS_AMSU_RADIANCE)
!         call get_expected_radiance(state_handle, ens_size, location, obs_def%key, expected_obs, istatus)
! END DART PREPROCESS GET_EXPECTED_OBS_FROM_DEF


! BEGIN DART PREPROCESS READ_OBS_DEF
!   case(AIRS_AMSU_RADIANCE)
!      call read_rttov_metadata(obs_def%key, key, ifile, fform)
! END DART PREPROCESS READ_OBS_DEF


! BEGIN DART PREPROCESS WRITE_OBS_DEF
!   case(AIRS_AMSU_RADIANCE)
!      call write_rttov_metadata(obs_def%key, ifile, fform)
! END DART PREPROCESS WRITE_OBS_DEF


! BEGIN DART PREPROCESS INTERACTIVE_OBS_DEF
!   case(AIRS_AMSU_RADIANCE)
!      call interactive_rttov_metadata(obs_def%key)
! END DART PREPROCESS INTERACTIVE_OBS_DEF


! BEGIN DART PREPROCESS MODULE CODE
module obs_def_rttov_mod

use        types_mod, only : r8, PI, metadatalength, MISSING_R8
use    utilities_mod, only : register_module, error_handler, E_ERR, E_WARN, E_MSG, &
                             logfileunit, get_unit, open_file, close_file, nc_check, &
                             file_exist, ascii_file_format
use     location_mod, only : location_type, set_location, get_location, &
                             VERTISHEIGHT, VERTISLEVEL, set_location_missing
use     obs_kind_mod, only : QTY_GEOPOTENTIAL_HEIGHT, QTY_SOIL_MOISTURE
use  assim_model_mod, only : interpolate

use obs_def_utilities_mod, only : track_status
use ensemble_manager_mod,  only : ensemble_type

use typesizes
use netcdf

implicit none
private

public ::            set_rttov_metadata, &
                     get_rttov_metadata, &
                    read_rttov_metadata, &
                   write_rttov_metadata, &
             interactive_rttov_metadata, &
                  get_expected_radiance

! version controlled file description for error handling, do not edit
character(len=256), parameter :: source   = &
   "$URL$"
character(len=32 ), parameter :: revision = "$Revision$"
character(len=128), parameter :: revdate  = "$Date$"

character(len=512) :: string1, string2
logical, save      :: module_initialized = .false.

! Metadata for rttov observations.

! AIRS is sensor 11 w/ 1-2378 channels (visible/near infrared/infrared)
! AMSU-A is sensor 3 with 1-15 channels (infrared/microwave)

!FIXME
type obs_metadata
   private
!    sat az/el
!    sun az/el
!    platform
!    instrument
!    channel
   real(r8)            :: sat_az     ! azimuth of satellite position
   real(r8)            :: sat_ze     ! azimuth of satellite position
   real(r8)            :: sun_az     ! zenith of solar position
   real(r8)            :: sun_ze     ! zenith of solar position
   integer             :: platform   ! see rttov user guide
   integer             :: sensor     ! see rttov user guide
   integer             :: channel    ! each channel is a different obs
   ! more here as we need it
end type obs_metadata

type(obs_metadata), allocatable, dimension(:) :: observation_metadata
type(obs_metadata) :: missing_metadata
character(len=5), parameter :: RTTOVSTRING = 'rttov'

logical :: debug = .FALSE.
integer :: MAXrttovkey = 100000  !FIXME - some initial number of obs
integer ::    rttovkey = 0       ! useful length of metadata arrays

contains


!----------------------------------------------------------------------------

subroutine initialize_module

call register_module(source, revision, revdate)

module_initialized = .true.

missing_metadata%sat_az   = MISSING_R8
missing_metadata%sat_ze   = MISSING_R8
missing_metadata%sun_az   = MISSING_R8
missing_metadata%sun_ze   = MISSING_R8
missing_metadata%platform = MISSING_I
missing_metadata%sensor   = MISSING_I
missing_metadata%channel  = MISSING_I

allocate(observation_metadata(MAXrttovkey))

observation_metadata(:) = missing_metadata

!FIXME call an init routine for rttov here

end subroutine initialize_module

!----------------------------------------------------------------------
! Fill the module storage metadata for a particular observation.

subroutine set_rttov_metadata(key, sat_az, sat_ze, sun_az, sun_ze, platform, sensor, channel)
integer,  intent(out) :: key
real(r8), intent(in)  :: sat_az, sat_ze, sun_az, sun_ze
integer,  intent(in)  :: platform, sensor, channel

if ( .not. module_initialized ) call initialize_module

rttovkey = rttovkey + 1  ! increase module storage used counter

! Make sure the new key is within the length of the metadata arrays.
call grow_metadata(rttovkey,'set_rttov_metadata')

key = rttovkey ! now that we know its legal

observation_metadata(key)%sat_az    = sat_az
observation_metadata(key)%sat_ze    = sat_ze
observation_metadata(key)%sun_az    = sun_az
observation_metadata(key)%sun_ze    = sun_ze
observation_metadata(key)%platform  = platform
observation_metadata(key)%sensor    = sensor
observation_metadata(key)%channel   = channel

end subroutine set_rttov_metadata


!----------------------------------------------------------------------
! Query the metadata in module storage for a particular observation.

subroutine get_rttov_metadata(key, sat_az, sat_ze, sun_az, sun_ze, platform, sensor, channel)
integer,  intent(in)  :: key
real(r8), intent(out) :: sat_az, sat_ze, sun_az, sun_ze
integer,  intent(out) :: platform, sensor, channel

if ( .not. module_initialized ) call initialize_module

! Make sure the desired key is within the length of the metadata arrays.
call key_within_range(key,'get_rttov_metadata')

sat_az   = observation_metadata(key)%sat_az
sat_ze   = observation_metadata(key)%sat_ze
sun_az   = observation_metadata(key)%sun_az
sun_ze   = observation_metadata(key)%sun_ze
platform = observation_metadata(key)%platform
sensor   = observation_metadata(key)%sensor
channel  = observation_metadata(key)%channel

end subroutine get_rttov_metadata


!----------------------------------------------------------------------
! This routine reads the metadata for radiance obs

subroutine read_rttov_metadata(key, obsID, ifile, fform)
integer,          intent(out)          :: key    ! index into local metadata
integer,          intent(in)           :: obsID
integer,          intent(in)           :: ifile
character(len=*), intent(in), optional :: fform

! temp variables
logical           :: is_asciifile
integer           :: ierr
character(len=5)  :: header
integer           :: oldkey
real(r8)          :: sat_az, sat_ze, sun_az, sun_ze
integer           :: platform, sensor, channel

if ( .not. module_initialized ) call initialize_module

is_asciifile = ascii_file_format(fform)

write(string2,*)'observation #',obsID

if ( is_asciifile ) then
   read(ifile, *, iostat=ierr) header
   call check_iostat(ierr,'read_rttov_metadata','header',string2)
   if (trim(header) /= trim(rttovSTRING)) then
       write(string1,*)"Expected radiance header ["//RTTOVSTRING//"] in input file, got ["//header//"]"
       call error_handler(E_ERR, 'read_rttov_metadata', string1, source, revision, revdate, text2=string2)
   endif
   read(ifile, *, iostat=ierr) sat_az, sat_ze, sun_az, sun_ze
   call check_iostat(ierr,'read_rttov_metadata','sat,sun az/ze',string2)
   read(ifile, *, iostat=ierr) platform, sensor, channel
   call check_iostat(ierr,'read_rttov_metadata','platform/sensor/channel',string2)
   read(ifile, *, iostat=ierr) oldkey
   call check_iostat(ierr,'read_rttov_metadata','oldkey',string2)
else
   read(ifile, iostat=ierr) header
   call  check_iostat(ierr,'read_rttov_metadata','header',string2)
   if (trim(header) /= trim(rttovSTRING)) then
       write(string1,*)"Expected radiance header ["//RTTOVSTRING//"] in input file, got ["//header//"]"
       call error_handler(E_ERR, 'read_rttov_metadata', string1, source, revision, revdate, text2=string2)
   endif
   read(ifile, iostat=ierr) sat_az, sat_ze, sun_az, sun_ze
   call check_iostat(ierr,'read_rttov_metadata','sat,sun az/ze',string2)
   read(ifile, iostat=ierr) platform, sensor, channel
   call check_iostat(ierr,'read_rttov_metadata','platform/sensor/channel',string2)
   read(ifile, iostat=ierr) oldkey
   call check_iostat(ierr,'read_rttov_metadata','oldkey',string2)
endif

! The oldkey is thrown away.

! Store the metadata in module storage. The new key is returned.
call set_rttov_metadata(key, sat_az, sat_ze, sun_az, sun_ze, platform, sensor, channel)

end subroutine read_rttov_metadata


!----------------------------------------------------------------------
! writes the metadata for radiance observations.

subroutine write_rttov_metadata(key, ifile, fform)

integer,           intent(in)           :: key
integer,           intent(in)           :: ifile
character(len=*),  intent(in), optional :: fform

logical  :: is_asciifile
real(r8) :: sat_az, sat_ze, sun_az, sun_ze
integer  :: platform, sensor, channel


if ( .not. module_initialized ) call initialize_module

! given the index into the local metadata arrays - retrieve
! the metadata for this particular observation.

call get_rttov_metadata(key, sat_az, sat_ze, sun_az, sun_ze, platform, sensor, channel)

is_asciifile = ascii_file_format(fform)

if (is_asciifile) then
   write(ifile, *) trim(rttovSTRING)
   write(ifile, *) sat_az, sat_ze, sun_az, sun_ze
   write(ifile, *) platform, sensor, channel
   write(ifile, *) key
else
   write(ifile   ) trim(rttovSTRING)
   write(ifile   ) sat_az, sat_ze, sun_az, sun_ze
   write(ifile   ) platform, sensor, channel
   write(ifile   ) key
endif

end subroutine write_rttov_metadata


!----------------------------------------------------------------------

subroutine interactive_rttov_metadata(key)
integer, intent(out) :: key

real(r8)          :: sat_az, sat_ze, sun_az, sun_ze
integer           :: platform, sensor, channel

if ( .not. module_initialized ) call initialize_module

! Prompt for input for the required metadata

sat_az   = interactive_r('sat_az    satellite azimuth [degrees]', minvalue = 0.0_r8, maxvalue = 360.0_r8)
sat_ze   = interactive_r('sat_ze    satellite zenith [degrees]',  minvalue = 0.0_r8, maxvalue = 90.0_r8)
sun_az   = interactive_r('sun_az    solar azimuth [degrees]',     minvalue = 0.0_r8, maxvalue = 360.0_r8)
sun_ze   = interactive_r('sun_ze    solar zenith [degrees]',      minvalue = 0.0_r8, maxvalue = 90.0_r8)
platform = interactive_i('platform  RTTOV Platform number [see docs]',     minvalue = 1)
sensor   = interactive_i('sensor    RTTOV Sensor number [see docs]',       minvalue = 1)
channel  = interactive_i('channel   Instrument channel number [see docs]', minvalue = 1)

call set_rttov_metadata(key, sat_az, sat_ze, sun_az, sun_ze, platform, sensor, channel)

end subroutine interactive_rttov_metadata


!----------------------------------------------------------------------
! prompt for a real value, optionally setting min and/or max limits
! loops until valid value input.

function interactive_r(str1,minvalue,maxvalue)
real(r8)                       :: interactive_r
character(len=*),   intent(in) :: str1
real(r8), optional, intent(in) :: minvalue
real(r8), optional, intent(in) :: maxvalue

integer :: i

interactive_r = MISSING_R8

! Prompt with a minimum amount of error checking

if (present(minvalue) .and. present(maxvalue)) then

   interactive_r = minvalue - 1.0_r8
   MINMAXLOOP : do i = 1
      if ((interactive_r >= minvalue) .and. (interactive_r <= maxvalue)) exit MINMAXLOOP
      write(*, *) 'Enter '//str1
      read( *, *) interactive_r
   end do MINMAXLOOP

elseif (present(minvalue)) then

   interactive_r = minvalue - 1.0_r8
   MINLOOP : do i=1
      if (interactive_r >= minvalue) exit MINLOOP
      write(*, *) 'Enter '//str1
      read( *, *) interactive_r
   end do MINLOOP

elseif (present(maxvalue)) then

   interactive_r = maxvalue + 1.0_r8
   MAXLOOP : do i=1
      if (interactive_r <= maxvalue) exit MAXLOOP
      write(*, *) 'Enter '//str1
      read( *, *) interactive_r
   end do MAXLOOP

else ! anything goes ... cannot check
      write(*, *) 'Enter '//str1
      read( *, *) interactive_r
endif

end function interactive_r


!----------------------------------------------------------------------
! prompt for an integer value, optionally setting min and/or max limits
! loops until valid value input.

function interactive_i(str1,minvalue,maxvalue)
integer                        :: interactive_i
character(len=*),   intent(in) :: str1
integer,  optional, intent(in) :: minvalue
integer,  optional, intent(in) :: maxvalue

integer :: i

interactive_i = MISSING_I

! Prompt with a minimum amount of error checking

if (present(minvalue) .and. present(maxvalue)) then

   interactive_i = minvalue - 1
   MINMAXLOOP : do i = 1
      if ((interactive_i >= minvalue) .and. (interactive_i <= maxvalue)) exit MINMAXLOOP
      write(*, *) 'Enter '//str1
      read( *, *) interactive_i
   end do MINMAXLOOP

elseif (present(minvalue)) then

   interactive_i = minvalue - 1
   MINLOOP : do i=1
      if (interactive_i >= minvalue) exit MINLOOP
      write(*, *) 'Enter '//str1
      read( *, *) interactive_i
   end do MINLOOP

elseif (present(maxvalue)) then

   interactive_i = maxvalue + 1
   MAXLOOP : do i=1
      if (interactive_i <= maxvalue) exit MAXLOOP
      write(*, *) 'Enter '//str1
      read( *, *) interactive_i
   end do MAXLOOP

else ! anything goes ... cannot check
      write(*, *) 'Enter '//str1
      read( *, *) interactive_i
endif

end function interactive_i


!----------------------------------------------------------------------

subroutine get_expected_radiance(state_handle, ens_size, location, key, val, istatus)

type(ensemble_type), intent(in)  :: state_handle
integer,             intent(in)  :: ens_size
type(location_type), intent(in)  :: location          ! location of obs
integer,             intent(in)  :: key               ! key into module metadata
real(r8),            intent(out) :: val(ens_size)     ! value of obs
integer,             intent(out) :: istatus(ens_size) ! status of the calculation

!FIXME - this all gets replaced by code from the example program

integer  :: key
real(r8) :: sat_az, sat_ze, sun_az, sun_ze
integer  :: platform, sensor, channel

real(r8), allocatable :: temperature(:,:), pressure(:,:), moisture(:,:)
integer :: this_istatus(ens_size)

integer  :: i, zi, nlevels
real(r8) :: loc_array(3)
real(r8) :: loc_lon, loc_lat
real(r8) :: loc_value(ens_size)
type(location_type) :: loc
integer :: imem
logical :: return_now
character(len=*), parameter :: routine = 'get_expected_radiance'

!=================================================================================

if ( .not. module_initialized ) call initialize_module

val = 0.0_r8 ! set return value early

! Make sure the desired key is within the length of the metadata arrays.
call key_within_range(key, routine)

call get_rttov_metadata(key, sat_az, sat_ze, sun_az, sun_ze, platform, sensor, channel)

!=================================================================================
! Determine the number of model levels 
! using only the standard DART interfaces to model
!=================================================================================

loc_array = get_location(location) ! loc is in DEGREES
loc_lon   = loc_array(1)
loc_lat   = loc_array(2)

!FIXME: these interp results are unused. make it a cheap quantity to ask for.
nlevels = 0
COUNTLEVELS : do i = 1,maxlayers
   loc = set_location(loc_lon, loc_lat, real(i,r8), VERTISLEVEL)
   call interpolate(state_handle, ens_size, loc, QTY_PRESSURE, loc_value, this_istatus)
   if ( any(this_istatus /= 0 ) ) exit COUNTLEVELS
   nlevels = nlevels + 1
enddo COUNTLEVELS

if ((nlevels == maxlayers) .or. (nlevels == 0)) then
   write(string1,*) 'FAILED to determine number of levels in model.'
   if (debug) call error_handler(E_MSG,routine,string1,source,revision,revdate)
   istatus = 1
   val     = MISSING_R8
   return
else
!   if (debug) write(*,*)routine // 'we have ',nlevels,' model levels'
endif

! now get needed info - t,p,q for starters

allocate(temperature(ens_size, nlevels), &
            pressure(ens_size, nlevels), &
            moisture(ens_size, nlevels))

! Set all of the istatuses back to zero for track_status
istatus = 0

GETLEVELDATA : do i = 1,nlevels
   loc = set_location(loc_lon, loc_lat, real(i,r8), VERTISLEVEL)

   call interpolate(state_handle, ens_size, loc, QTY_PRESSURE, temperature(:,i), this_istatus)
   call track_status(ens_size, this_istatus, val, istatus, return_now)
   if (return_now) return

   call interpolate(state_handle, ens_size, loc, QTY_TEMPERATURE, pressure(:, i), this_istatus)
   call track_status(ens_size, this_istatus, val, istatus, return_now)
   if (return_now) return

   call interpolate(state_handle, ens_size, loc, QTY_SPECIFIC_HUMIDITY, moisture(:, i), this_istatus)
   call track_status(ens_size, this_istatus, val, istatus, return_now)
   if (return_now) return

   ! FIXME: what else?

enddo GETLEVELDATA


!FIXME initialize the profile info here for call to rttov()


deallocate(temperature, pressure, moisture)

!=================================================================================
! ... and finally set the return the radiance forward operator value

where (istatus == 0) val = radiance
where (istatus /= 0) val = missing_r8

end subroutine get_expected_radiance


!----------------------------------------------------------------------
! this is a fatal error routine.  use with care - if a forward
! operator fails it should return a bad error code, not die.
! useful in read/write routines where it is fatal to fail.

subroutine check_iostat(istat, routine, varname, msgstring)
integer,          intent(in) :: istat
character(len=*), intent(in) :: routine
character(len=*), intent(in) :: varname
character(len=*), intent(in) :: msgstring

if ( istat /= 0 ) then
   write(string1,*)'istat should be 0 but is ',istat,' for '//varname
   call error_handler(E_ERR, routine, string1, source, revision, revdate, text2=msgstring)
end if

end subroutine check_iostat


!----------------------------------------------------------------------
! Make sure we are addressing within the metadata arrays

subroutine key_within_range(key, routine)

integer,          intent(in) :: key
character(len=*), intent(in) :: routine

! fine -- no problem.
if ((key > 0) .and. (key <= rttovkey)) return

! Bad news. Tell the user.
write(string1, *) 'key (',key,') not within known range ( 1,', rttovkey,')'
call error_handler(E_ERR,routine,string1,source,revision,revdate)

end subroutine key_within_range


!----------------------------------------------------------------------
! If the allocatable metadata arrays are not big enough ... try again

subroutine grow_metadata(key, routine)

integer,          intent(in) :: key
character(len=*), intent(in) :: routine

integer :: orglength
type(obs_metadata), allocatable, dimension(:) :: safe_metadata

! fine -- no problem.
if ((key > 0) .and. (key <= MAXrttovkey)) return

! Check for some error conditions.
if (key < 1) then
   write(string1, *) 'key (',key,') must be >= 1'
   call error_handler(E_ERR,routine,string1,source,revision,revdate)
elseif (key >= 2*MAXrttovkey) then
   write(string1, *) 'key (',key,') really unexpected.'
   write(string2, *) 'doubling storage will not help.'
   call error_handler(E_ERR,routine,string1,source,revision,revdate, &
                      text2=string2)
endif

orglength   = MAXrttovkey
MAXrttovkey = 2 * orglength

! News. Tell the user we are increasing storage.
write(string1, *) 'key (',key,') exceeds Nmax_radiance_obs (',orglength,')'
write(string2, *) 'Increasing Nmax_radiance_obs to ',MAXrttovkey
call error_handler(E_MSG,routine,string1,source,revision,revdate,text2=string2)

allocate(safe_metadata(orglength))
safe_metadata(:) = observation_metadata(:)

deallocate(observation_metadata)
  allocate(observation_metadata(MAXrttovkey))

observation_metadata(1:orglength)              = safe_metadata(:)
observation_metadata(orglength+1:MAXrttovkey) = missing_metadata

deallocate(safe_metadata)

end subroutine grow_metadata

!----------------------------------------------------------------------

end module obs_def_rttov_mod

! END DART PREPROCESS MODULE CODE

! <next few lines under version control, do not edit>
! $URL$
! $Id$
! $Revision$
! $Date$
