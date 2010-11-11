===================================================================
 ``uam agent for mcollective`` -- Manage local linux users
===================================================================

``uam`` is licensed under the GPL, see the file ``COPYING`` for
more information.

``uam`` agent uses and extends puppet user type to manage users
on a Linux system. This requires puppet exist on the node hosting
this agent, if not to be used as puppet to provide it's libraries.


Install
=======

- Grab it from github::

    git clone git://github.com/jofu/uam-agent.git

- Copy ``uam.rb`` to the mcollective agent directory on all 
  of your mcollective-managed machines.

- On your client machine, install the ``mc-uam`` control script

TODO
====


Author
======

Jonathan Furrer, <jofu@jofu.com>, 2010-11-10
