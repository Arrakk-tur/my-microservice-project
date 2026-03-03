
resource "aws_db_instance" "this" {
  count                  = var.use_aurora ? 0 : 1
  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  parameter_group_name   = aws_db_parameter_group.rds_pg[0].name
  skip_final_snapshot    = true
  multi_az               = false
}