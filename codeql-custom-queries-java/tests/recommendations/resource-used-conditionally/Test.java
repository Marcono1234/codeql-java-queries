import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;

class Test {
    void badTrueBranch(Path path, boolean b) throws IOException {
        try (InputStream in = Files.newInputStream(path)) {
            if (b) {
                in.read();
            }
        }
    }

    void badFalseBranch(Path path, boolean b) throws IOException {
        try (InputStream in = Files.newInputStream(path)) {
            if (b) {
                System.out.println("unused");
            } else {
                in.read();
            }
        }
    }

    void badException(Path path, boolean b) throws IOException {
        try (InputStream in = Files.newInputStream(path)) {
            if (b) {
                throw new IllegalArgumentException();
            }
            in.read();
        }
    }

    void badNestedConditions(Path path, boolean b1, boolean b2) throws IOException {
        try (InputStream in = Files.newInputStream(path)) {
            // Only outermost condition should be reported
            if (b1) {
                if (b2) {
                    in.read();
                }
            }
        }
    }

    void badMultipleThrownExceptions(Path path, boolean b1, boolean b2) throws IOException {
        try (InputStream in = Files.newInputStream(path)) {
            // Only first one should be reported
            if (b1) {
                throw new IllegalArgumentException("b1");
            }
            if (b2) {
                throw new IllegalArgumentException("b2");
            }
            in.read();
        }
    }

    void goodNoUse(Path path) throws IOException {
        try (OutputStream out = Files.newOutputStream(path)) {
            // Resource is not used; could be the case for resources representing locks or scopes
        }
    }

    void goodDifferentConditionBranches(Path path, boolean b) throws IOException {
        try (OutputStream out = Files.newOutputStream(path)) {
            // Condition guards all access, but on different branches
            if (b) {
                out.write(1);
            } else {
                out.write(2);
            }
        }
    }

    void goodGuardAroundTry(Path path) throws IOException {
        if (Files.isRegularFile(path)) {
            try (InputStream in = Files.newInputStream(path)) {
                in.read();
            }
        }
    }

    void goodLoopAroundUse(InputStream in, Path outPath) throws IOException {
        try (OutputStream out = Files.newOutputStream(outPath)) {
            byte[] buffer = new byte[1024];
            int read;
            while ((read = in.read(buffer)) != -1) {
                // Used within loop
                out.write(buffer, 0, read);
            }
        }
    }

    void goodUseInLoopCondition(Path inPath, OutputStream out) throws IOException {
        try (InputStream in = Files.newInputStream(inPath)) {
            byte[] buffer = new byte[1024];
            int read;

            // Used within loop condition
            while ((read = in.read(buffer)) != -1) {
                // Used within loop
                out.write(buffer, 0, read);
            }
        }
    }

    void goodUsedByOtherResource(Path path, boolean writeMagicBytes) throws IOException {
        try (
            OutputStream out = Files.newOutputStream(path);
            // Used by other resource
            Writer writer = new OutputStreamWriter(out, StandardCharsets.UTF_8);
        ) {
            if (writeMagicBytes) {
                out.write(1);
            }

            writer.write("test");
        }
    }
}