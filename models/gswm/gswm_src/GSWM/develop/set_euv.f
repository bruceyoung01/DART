      subroutine set_euv()
c
c Reads euv heating from harmonic fit of tgcm secondary history:
c Input file has 36 latitudes on 2.5 degree grid, and 36 altitudes
c from 100km to 400km, unevenly spaced grid.
c
c ----Call from main_2 with call set_euv(mois,period,nzonal,f107)----
c
c Period can be ignored if there is a test in main_2 for migrating tide
c
c If not, this code should be modified to open apprpriate non-migrating files
c based on (period, nzonal) and to interpolate and report appropriate
c imaginary components of euv heating.  It already reads the imaginary values
c but does nothing with them. jhackney 8/98
c
c The files are made by running idl program 'euv.pro' in
c ~hackney/GSWM/idl/fourier on tgcmproc secondary history output
c (QSOLAR field with UV removed)
c
C Modified seasonal logic: TIE-GCM Equinox--> March and September
C					changed from April & October
c						M. Hagan 9/25/98
C Modified seasonal logic: TIE-GCM Equinox--> December and June
C					changed from January & July
c						M. Hagan 10/19/98
c
      implicit none
c
      character*11 flnm(12)
      integer mois,nzonal,f107,sesn,nss
      integer i,j,m,n,ierr,iz,findex,mx,ny,k
      real period,freq,flux
      real euvlat(36),reuv(36,36),ieuv(36,36),euvalt(36)
      real zx1(36),zxm(36)
      real zy1(36),zyn(36)
      real zxy11,zxym1,zxy1n,zxymn,sigmat
      real deuv(36,36,3),temp(108)
      real dumlat(36),dumreuv(36,36),dumieuv(36,36)
c
      data flnm /'euv_eqn.diu','euv_eqn.sem','euv_eqm.diu',
     +     'euv_eqm.sem','euv_eqx.diu','euv_eqx.sem','euv_son.diu',
     +     'euv_son.sem','euv_som.diu','euv_som.sem','euv_sox.diu',
     +     'euv_sox.sem'/
c
        common /euv/mx,ny,iz,euvlat,euvalt,reuv,ieuv,deuv,sigmat,f107
        common/mode/NZONAL,PERIOD,FREQ,MOIS,NSS,FLUX
c
      parameter (m=36,n=36)
c
      iz=m
      mx=m
      ny=n
      sigmat=1.0
c
c Read in file info, test version only

c
      if(nzonal.gt.2.or.nzonal.lt.1.0)then
         print*,'seteuv error: nzonal out of range for migrating tide'
         print*,'seteuv program stopped'
         stop
      endif
c
      if(mois.eq.3.or.mois.eq.9) then
         sesn=1
      elseif(mois.eq.6.or.mois.eq.12)then
         sesn=2
      else
         print*,'seteuv error: no data for month ',mois
         print*,'seteuv program stopped'
         stop
      endif
c
c Calculate the index for the correct input file above

      findex=6*(sesn-1)+2*(f107-1)+nzonal
c
c Open euv heating in J/(kg-s)

      open(17,file=flnm(findex),status='old')
      print*,'Opening ',flnm(findex)
c
c Read in euv latitudes, 36 x -87.5 to 87.5 (S to N)

      read(17,*)
      read(17,100)(euvlat(i),i=1,m)
c
c Read heating values for every altitude (j) and latitude (i)

      do j=1,n
         read(17,*)euvalt(j)
         do k=1,6
            read(17,200)(reuv(i,j),i=(k-1)*m/6+1,k*m/6)
            read(17,200)(ieuv(i,j),i=(k-1)*m/6+1,k*m/6)
         end do
      end do
c
 100  format(36(f7.2))
 200  format(6(e13.5))
c
c Reverse the latitudes and the heating values corresponding to them for
c strictly increasing latitude coordinates required by interpolation toolkit

c
c First save latitude-reversed values to a dummy

      do j=1,n
         do i=1,m
            dumlat(i)=euvlat(m-i+1)
            dumreuv(i,j)=reuv(m-i+1,j)
            dumieuv(i,j)=ieuv(m-i+1,j)
         enddo
      enddo
c
c Return dummy values to orignal variable names and convert latitude to colat
c by subtracting it from 90.

      do j=1,n
c         print*,euvalt(j)
         do i=1,m
            euvlat(i)=90.-dumlat(i)
            reuv(i,j)=dumreuv(i,j)
            ieuv(i,j)=dumieuv(i,j)
c            print*,i,euvlat(i),reuv(i,j),ieuv(i,j)
         enddo
      enddo
c
c Spot for interpolation call to surf1
c
      call surf1(mx,ny,euvlat,euvalt,reuv,m,zx1,zxm,zy1,zyn,zxy11,zxym1,
     +     zxy1n,zxymn,255,deuv,temp,sigmat,ierr)
c
c     return
      end
