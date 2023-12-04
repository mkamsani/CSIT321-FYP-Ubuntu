# Ubuntu Development Environment

## LiveCD Installation

### Download Ubuntu Server

![](slidev/images/1-download.png)

![](slidev/images/2-download-complete.png)

### Create a Virtual Machine (VM)

I'm using GNOME Boxes,
but you can use other hypervisors like VirtualBox or VMWare:

![](slidev/images/3-create-vm.png)

I increased the default RAM to 8GB and storage to 80GB:

![](slidev/images/4-create-vm-modify-resources.png)

### Boot the VM

![](slidev/images/5-boot-grub.png)

#### Follow the installation wizard

![](slidev/images/6-wizard-lang.png)

I selected `continue without updating`:

![](slidev/images/7-wizard-update.png)

![](slidev/images/8-wizard-kb.png)

I added `Search for third-party drivers`:

![](slidev/images/9-wizard-install-type.png)

I omitted `LVM`:

![](slidev/images/10-wizard-partition.png)

Your partitioning should look something like this:

![](slidev/images/11-wizard-parition-summary.png)

Set up something super basic for your user:

![](slidev/images/12-wizard-profile.png)

Skip the Ubuntu Pro advertisement:

![](slidev/images/13-wizard-advertisement.png)

Add your GitHub SSH keys, so you can immediately SSH into your VM afterward:

![](slidev/images/14-wizard-ssh-github-import.png)

No third-drivers needed for my VM, but your mileage may vary:

![](slidev/images/15-wizard-no-driver.png)

Don't tick any of these:

![](slidev/images/16-wizard-server-snaps-not-needed.png)

Once complete, you'll see this:

![](slidev/images/17-wizard-install-complete.png)

Remove your installation media:

![](slidev/images/18-vm-remove-cd.png)

## Post Installation

This first part is a bit iffy.

When the system boots, you'll see a bunch of output related to your SSH keys.
Ignore the output and hit `Enter` to get a prompt, maybe you'll get `Login incorrect`.
After that, enter your username and password to log in:

![](slidev/images/19-reboot-login.png)

Enter `ip a` to get your IP address. Usually the default network interface is `enp1s0`.
Take the `inet` or `inet6` address and SSH into your VM from your host.

From your host (i.e. Windows/macOS/etc.), SSH into your VM:

`ssh <username>@<ip-address>`

### Prompt on apt-get upgrade

Once you're in, you can copy-paste commands.

Update the system:

```sh
DEBIAN_FRONTEND=noninteractive \
sudo apt-get update  -y -qq && \
sudo apt-get upgrade -y -qq
```

**IF** you see this:

![](slidev/images/20-reboot-systemd-services-curses-prompt.png)

Select `<Ok>`.

Next, manually install `curl` and `wget`. `curl` is installed by default on
Ubuntu Server, but wget is not. But on Docker Ubuntu or WSL2, you might get
the opposite result. We resolve this by installing both, along with git:

```sh
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y -qq curl git wget
```

### Rest of script

```sh
wget -qO- https://raw.githubusercontent.com/mkamsani/CSIT321-FYP-Ubuntu/main/install.sh | sh
```

