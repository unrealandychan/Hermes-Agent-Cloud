# ebs.tf — Persistent data volume for Hermes Agent
#
# This EBS volume is intentionally SEPARATE from the root block device.
# The EC2 instance can be terminated, upgraded, or replaced while this
# volume (and all Hermes data) survives. Re-attach it to any new instance
# via:  hermes-agent-cloud ebs attach
#
# ─── Volume ──────────────────────────────────────────────────────────────────
resource "aws_ebs_volume" "hermes_data" {
  count             = var.ebs_enabled ? 1 : 0
  availability_zone = aws_instance.hermes.availability_zone
  size              = var.ebs_size
  type              = "gp3"
  encrypted         = true
  throughput        = 125    # MiB/s — gp3 baseline
  iops              = 3000   # gp3 baseline, free

  tags = {
    Name    = "hermes-data"
    Project = "Hermes-Agent-Cloud"
    # Keeps the volume alive even after the instance is destroyed
    KeepOnTerminate = "true"
  }

  lifecycle {
    # Prevents accidental deletion via `terraform destroy` (full run).
    # To intentionally remove: terraform destroy -target=aws_ebs_volume.hermes_data
    prevent_destroy = true
    # Do not force re-create if size or type is changed — AWS supports live resize
    ignore_changes  = [size, type, iops, throughput]
  }
}

# ─── Attachment ───────────────────────────────────────────────────────────────
resource "aws_volume_attachment" "hermes_data" {
  count       = var.ebs_enabled ? 1 : 0
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.hermes_data[0].id
  instance_id = aws_instance.hermes.id

  # Allow detach without stopping the instance (needed for live migration)
  force_detach         = false
  skip_destroy         = false
  stop_instance_before_detaching = false
}
